import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesForecast from '@salesforce/apex/SalesForecastController.getSalesForecast';
import getSubordinateUsers from '@salesforce/apex/SalesForecastController.getSubordinateUsers';

const DETAIL_COLUMNS = [
    { label: '商談名',       fieldName: 'name',            type: 'text',     sortable: true },
    { label: '取引先名',     fieldName: 'accountName',     type: 'text',     sortable: true },
    { label: '金額',         fieldName: 'amount',          type: 'currency', sortable: true, cellAttributes: { alignment: 'right' } },
    { label: '完了予定日',   fieldName: 'closeDate',       type: 'date',     sortable: true, typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' } },
    { label: 'フェーズ',     fieldName: 'stageName',       type: 'text',     sortable: true },
    { label: '確度',         fieldName: 'probability',     type: 'percent',  sortable: true, cellAttributes: { alignment: 'right' } },
    { label: '売上予測分類', fieldName: 'forecastCategory', type: 'text',    sortable: true },
    { label: '所有者',       fieldName: 'ownerName',       type: 'text',     sortable: true }
];

const FORECAST_TYPE_OPTIONS = [
    { label: 'Closed',   value: 'Closed' },
    { label: 'Commit',   value: 'Commit' },
    { label: 'BestCase', value: 'BestCase' },
    { label: 'Pipeline', value: 'Pipeline' }
];

export default class SalesForecastView extends LightningElement {
    headerTitle = '売上予測照会';

    @track isLoading = false;
    @track hasError  = false;
    @track errorMessage = '';

    @track userOptions = [];
    @track selectedUserId = '';

    forecastTypeOptions = FORECAST_TYPE_OPTIONS;
    @track selectedForecastTypes = ['Closed', 'Commit', 'BestCase', 'Pipeline'];

    @track showTarget          = false;
    @track showAchievementRate = false;
    @track showZeroRows        = false;

    // サマリソート
    @track summarySortField = 'month';
    @track summarySortAsc   = true;

    // 明細ソート
    @track sortedBy        = 'closeDate';
    @track sortedDirection = 'asc';

    // 取得データ
    @track summaryList = [];
    @track detailList  = [];
    @track lastUpdated = null;

    detailColumns = DETAIL_COLUMNS;

    connectedCallback() {
        this.loadUsers();
        this.loadForecast();
    }

    async loadUsers() {
        try {
            const users = await getSubordinateUsers();
            this.userOptions = users.map(u => ({ label: u.label, value: u.value }));
            if (this.userOptions.length > 0 && !this.selectedUserId) {
                this.selectedUserId = this.userOptions[0].value;
            }
        } catch (e) {
            this.showError(e.body ? e.body.message : e.message);
        }
    }

    async loadForecast() {
        if (this.selectedForecastTypes.length === 0) {
            this.showError('売上予測種別を1件以上選択してください');
            return;
        }
        this.isLoading = true;
        this.hasError  = false;
        try {
            const fiscalYear = new Date().getMonth() >= 3
                ? new Date().getFullYear()
                : new Date().getFullYear() - 1;

            const result = await getSalesForecast({
                targetUserId:  this.selectedUserId,
                fiscalYear:    fiscalYear,
                forecastTypes: this.selectedForecastTypes
            });

            this.summaryList = (result.summaryList || []).map(s => ({
                ...s,
                formattedTarget:          this.formatCurrency(s.targetAmount),
                formattedClosed:          this.formatCurrency(s.closedAmount),
                formattedCommit:          this.formatCurrency(s.commitAmount),
                formattedBestCase:        this.formatCurrency(s.bestCaseAmount),
                formattedPipeline:        this.formatCurrency(s.pipelineAmount),
                formattedAchievementRate: this.formatPercent(s.achievementRate)
            }));
            this.detailList  = result.detailList || [];
            this.lastUpdated = result.lastUpdated;
        } catch (e) {
            this.showError(e.body ? e.body.message : e.message);
        } finally {
            this.isLoading = false;
        }
    }

    // イベントハンドラ

    handleRefresh() {
        this.loadForecast();
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        this.loadForecast();
    }

    handleForecastTypeChange(event) {
        this.selectedForecastTypes = event.detail.value;
        this.loadForecast();
    }

    handleToggleTarget(event) {
        this.showTarget = event.detail.checked;
    }

    handleToggleAchievementRate(event) {
        this.showAchievementRate = event.detail.checked;
    }

    handleToggleZeroRows(event) {
        this.showZeroRows = event.detail.checked;
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (this.summarySortField === field) {
            this.summarySortAsc = !this.summarySortAsc;
        } else {
            this.summarySortField = field;
            this.summarySortAsc   = true;
        }
    }

    handleDetailSort(event) {
        this.sortedBy        = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
    }

    // Getters（リアクティブ）

    get filteredSummaryList() {
        let list = [...this.summaryList];

        if (!this.showZeroRows) {
            list = list.filter(r =>
                r.closedAmount   !== 0 ||
                r.commitAmount   !== 0 ||
                r.bestCaseAmount !== 0 ||
                r.pipelineAmount !== 0 ||
                r.targetAmount   !== 0
            );
        }

        list.sort((a, b) => {
            const va = a[this.summarySortField];
            const vb = b[this.summarySortField];
            const cmp = (va < vb ? -1 : va > vb ? 1 : 0);
            return this.summarySortAsc ? cmp : -cmp;
        });

        return list;
    }

    get sortedDetailList() {
        const list  = [...this.detailList];
        const field = this.sortedBy;
        const asc   = this.sortedDirection === 'asc';

        list.sort((a, b) => {
            const va = a[field];
            const vb = b[field];
            const cmp = (va == null ? -1 : vb == null ? 1 : va < vb ? -1 : va > vb ? 1 : 0);
            return asc ? cmp : -cmp;
        });
        return list;
    }

    get formattedLastUpdated() {
        if (!this.lastUpdated) return '';
        const d = new Date(this.lastUpdated);
        return d.toLocaleString('ja-JP', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
    }

    _sortIndicator(field) {
        if (this.summarySortField !== field) return '';
        return this.summarySortAsc ? '▲' : '▼';
    }

    get monthSortIndicator()           { return this._sortIndicator('month'); }
    get targetSortIndicator()          { return this._sortIndicator('targetAmount'); }
    get closedSortIndicator()          { return this._sortIndicator('closedAmount'); }
    get commitSortIndicator()          { return this._sortIndicator('commitAmount'); }
    get bestCaseSortIndicator()        { return this._sortIndicator('bestCaseAmount'); }
    get pipelineSortIndicator()        { return this._sortIndicator('pipelineAmount'); }
    get achievementRateSortIndicator() { return this._sortIndicator('achievementRate'); }

    // ユーティリティ

    formatCurrency(val) {
        if (val == null) return '¥0';
        return '¥' + Number(val).toLocaleString('ja-JP', { maximumFractionDigits: 0 });
    }

    formatPercent(val) {
        if (val == null) return '0.0%';
        return Number(val).toFixed(1) + '%';
    }

    showError(msg) {
        this.hasError     = true;
        this.errorMessage = msg;
        this.dispatchEvent(new ShowToastEvent({
            title:   'エラー',
            message: msg,
            variant: 'error'
        }));
    }
}
