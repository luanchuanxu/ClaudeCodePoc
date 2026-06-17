public with sharing class SalesForecastController {

    // DTO: サマリ行（月別集計）
    public class ForecastSummary {
        @AuraEnabled public String month { get; set; }
        @AuraEnabled public Decimal targetAmount { get; set; }
        @AuraEnabled public Decimal closedAmount { get; set; }
        @AuraEnabled public Decimal commitAmount { get; set; }
        @AuraEnabled public Decimal bestCaseAmount { get; set; }
        @AuraEnabled public Decimal pipelineAmount { get; set; }
        @AuraEnabled public Decimal achievementRate { get; set; }
    }

    // DTO: 明細行（商談）
    public class OpportunityDetail {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date closeDate { get; set; }
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public Decimal probability { get; set; }
        @AuraEnabled public String forecastCategory { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public String ownerId { get; set; }
        @AuraEnabled public Datetime lastModifiedDate { get; set; }
    }

    // DTO: 売上予測結果（サマリ＋明細）
    public class ForecastResult {
        @AuraEnabled public List<ForecastSummary> summaryList { get; set; }
        @AuraEnabled public List<OpportunityDetail> detailList { get; set; }
        @AuraEnabled public Datetime lastUpdated { get; set; }
    }

    // DTO: ユーザ選択肢
    public class UserOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    // 売上予測データ取得（S0001: Opportunity 月別集計）
    @AuraEnabled(cacheable=false)
    public static ForecastResult getSalesForecast(
        String targetUserId,
        Integer fiscalYear,
        List<String> forecastTypes
    ) {
        try {
            if (fiscalYear == null) {
                throw new AuraHandledException('fiscalYear は必須です');
            }
            String userId = String.isBlank(targetUserId)
                ? UserInfo.getUserId()
                : targetUserId;

            Date fiscalStart = Date.newInstance(fiscalYear, 4, 1);
            Date fiscalEnd   = Date.newInstance(fiscalYear + 1, 3, 31);

            String soql =
                'SELECT Id, Name, Account.Name, Amount, CloseDate, StageName, ' +
                '       Probability, ForecastCategoryName, Owner.Name, OwnerId, LastModifiedDate ' +
                'FROM Opportunity ' +
                'WHERE OwnerId = :userId ' +
                '  AND CloseDate >= :fiscalStart ' +
                '  AND CloseDate <= :fiscalEnd';

            if (forecastTypes != null && !forecastTypes.isEmpty()) {
                soql += ' AND ForecastCategoryName IN :forecastTypes';
            }

            soql += ' ORDER BY CloseDate ASC';

            List<Opportunity> opps = Database.query(soql);

            ForecastResult result = new ForecastResult();
            result.lastUpdated = Datetime.now();
            result.detailList  = buildDetailList(opps);
            result.summaryList = buildSummaryList(opps);
            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // 配下ユーザ一覧取得（S0002: UserRole / S0003: User）
    @AuraEnabled(cacheable=true)
    public static List<UserOption> getSubordinateUsers() {
        try {
            Id currentRoleId = [SELECT UserRoleId FROM User WHERE Id = :UserInfo.getUserId()].UserRoleId;

            Set<Id> roleIds = new Set<Id>();
            if (currentRoleId != null) {
                getSubordinateRoleIds(currentRoleId, roleIds);
            }

            List<UserOption> options = new List<UserOption>();
            // 自分自身を先頭に追加
            options.add(buildUserOption(UserInfo.getUserId(), UserInfo.getName()));

            if (!roleIds.isEmpty()) {
                for (User u : [
                    SELECT Id, Name
                    FROM User
                    WHERE UserRoleId IN :roleIds
                      AND IsActive = true
                    ORDER BY Name ASC
                ]) {
                    options.add(buildUserOption(u.Id, u.Name));
                }
            }
            return options;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // --- private helpers ---

    private static void getSubordinateRoleIds(Id roleId, Set<Id> collected) {
        for (UserRole r : [SELECT Id FROM UserRole WHERE ParentRoleId = :roleId]) {
            if (collected.add(r.Id)) {
                getSubordinateRoleIds(r.Id, collected);
            }
        }
    }

    private static UserOption buildUserOption(Id userId, String name) {
        UserOption opt = new UserOption();
        opt.label = name;
        opt.value = userId;
        return opt;
    }

    private static List<OpportunityDetail> buildDetailList(List<Opportunity> opps) {
        List<OpportunityDetail> details = new List<OpportunityDetail>();
        for (Opportunity o : opps) {
            OpportunityDetail d = new OpportunityDetail();
            d.id               = o.Id;
            d.name             = o.Name;
            d.accountName      = o.Account != null ? o.Account.Name : null;
            d.amount           = o.Amount != null ? o.Amount : 0;
            d.closeDate        = o.CloseDate;
            d.stageName        = o.StageName;
            d.probability      = o.Probability;
            d.forecastCategory = o.ForecastCategoryName;
            d.ownerName        = o.Owner != null ? o.Owner.Name : null;
            d.ownerId          = o.OwnerId;
            d.lastModifiedDate = o.LastModifiedDate;
            details.add(d);
        }
        return details;
    }

    private static List<ForecastSummary> buildSummaryList(List<Opportunity> opps) {
        Map<String, ForecastSummary> summaryMap = new Map<String, ForecastSummary>();

        for (Opportunity o : opps) {
            if (o.CloseDate == null) continue;
            String monthKey = o.CloseDate.year() + '/' +
                String.valueOf(o.CloseDate.month()).leftPad(2, '0');

            if (!summaryMap.containsKey(monthKey)) {
                ForecastSummary s = new ForecastSummary();
                s.month           = monthKey;
                s.targetAmount    = 0;
                s.closedAmount    = 0;
                s.commitAmount    = 0;
                s.bestCaseAmount  = 0;
                s.pipelineAmount  = 0;
                s.achievementRate = 0;
                summaryMap.put(monthKey, s);
            }

            ForecastSummary s = summaryMap.get(monthKey);
            Decimal amt = o.Amount != null ? o.Amount : 0;
            String fc   = o.ForecastCategoryName;

            if (fc == 'Closed')   { s.closedAmount   += amt; }
            else if (fc == 'Commit')    { s.commitAmount   += amt; }
            else if (fc == 'BestCase')  { s.bestCaseAmount += amt; }
            else if (fc == 'Pipeline')  { s.pipelineAmount += amt; }
        }

        List<String> sortedKeys = new List<String>(summaryMap.keySet());
        sortedKeys.sort();

        List<ForecastSummary> result = new List<ForecastSummary>();
        for (String key : sortedKeys) {
            ForecastSummary s = summaryMap.get(key);
            if (s.targetAmount != 0) {
                s.achievementRate = (s.closedAmount / s.targetAmount * 100).setScale(1);
            }
            result.add(s);
        }
        return result;
    }
}
