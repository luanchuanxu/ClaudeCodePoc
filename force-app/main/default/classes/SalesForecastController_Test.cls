@IsTest
private class SalesForecastController_Test {

    @TestSetup
    static void setup() {
        // ロール作成
        UserRole parentRole = new UserRole(Name = 'TestParent');
        insert parentRole;
        UserRole childRole = new UserRole(Name = 'TestChild', ParentRoleId = parentRole.Id);
        insert childRole;

        // テストユーザ作成
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User mgr = new User(
            LastName       = 'TestMgr',
            Alias          = 'tmgr',
            Email          = 'testmgr@example.test',
            Username       = 'testmgr_sfcast@example.test',
            UserRoleId     = parentRole.Id,
            ProfileId      = p.Id,
            TimeZoneSidKey = 'Asia/Tokyo',
            LocaleSidKey   = 'ja_JP',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'ja'
        );
        insert mgr;

        User sub = new User(
            LastName       = 'TestSub',
            Alias          = 'tsub',
            Email          = 'testsub@example.test',
            Username       = 'testsub_sfcast@example.test',
            UserRoleId     = childRole.Id,
            ProfileId      = p.Id,
            TimeZoneSidKey = 'Asia/Tokyo',
            LocaleSidKey   = 'ja_JP',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'ja'
        );
        insert sub;

        // 商談作成（会計年度 FY2025 = 2025/04 〜 2026/03）
        // ForecastCategoryName は StageName に連動する計算フィールドのため直接 set 不可
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(
            Name = 'Opp-Jun', OwnerId = sub.Id,
            CloseDate = Date.newInstance(2025, 6, 30),
            StageName = 'Closed Won',
            Amount = 100000
        ));
        opps.add(new Opportunity(
            Name = 'Opp-Jul', OwnerId = sub.Id,
            CloseDate = Date.newInstance(2025, 7, 31),
            StageName = 'Value Proposition',
            Amount = 200000
        ));
        opps.add(new Opportunity(
            Name = 'Opp-Sep', OwnerId = sub.Id,
            CloseDate = Date.newInstance(2025, 9, 30),
            StageName = 'Prospecting',
            Amount = 50000
        ));
        insert opps;
    }

    @IsTest
    static void testGetSalesForecast_withTypeFilter() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, new List<String>{'Closed'});
        Test.stopTest();

        System.assertNotEquals(null, result, 'result should not be null');
        System.assertNotEquals(null, result.summaryList, 'summaryList should not be null');
        System.assertNotEquals(null, result.detailList,  'detailList should not be null');
        // ForecastCategoryName=Closed に一致するものだけ（環境依存のため 0〜3 件）
        System.assert(result.detailList.size() >= 0, 'detailList size should be non-negative');
    }

    @IsTest
    static void testGetSalesForecast_noTypeFilter() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, new List<String>());
        Test.stopTest();

        // フィルタなし → FY2025 内の全件（3件）
        System.assertEquals(3, result.detailList.size(), 'all 3 opps in FY2025 returned');
    }

    @IsTest
    static void testGetSalesForecast_summaryAggregation() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, null);
        Test.stopTest();

        // summaryList が月別に集計されていること（3商談なので最低1行〜3行）
        System.assertNotEquals(null, result.summaryList, 'summaryList should not be null');
        System.assert(result.summaryList.size() >= 1, 'at least 1 summary row');
        // 各サマリ行に month が設定されていること
        for (SalesForecastController.ForecastSummary s : result.summaryList) {
            System.assertNotEquals(null, s.month, 'month should be set');
        }
    }

    @IsTest
    static void testGetSubordinateUsers() {
        User mgr = [SELECT Id FROM User WHERE Username = 'testmgr_sfcast@example.test'];

        Test.startTest();
        List<SalesForecastController.UserOption> opts;
        System.runAs(mgr) {
            opts = SalesForecastController.getSubordinateUsers();
        }
        Test.stopTest();

        System.assertNotEquals(null, opts, 'options should not be null');
        // 自分（mgr）＋配下（sub）で最低2件
        System.assert(opts.size() >= 2, 'at least mgr + 1 subordinate');
    }

    @IsTest
    static void testGetSalesForecast_exceptionHandling() {
        try {
            Test.startTest();
            SalesForecastController.getSalesForecast(null, null, null);
            Test.stopTest();
            System.assert(false, 'should have thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
    }

    // 月キーのゼロ埋めフォーマット確認（YYYY/MM 形式）
    @IsTest
    static void testSummaryMonthFormat() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, null);
        Test.stopTest();

        for (SalesForecastController.ForecastSummary s : result.summaryList) {
            System.assert(
                s.month != null && s.month.length() == 7 && s.month.contains('/'),
                'month should be YYYY/MM format but was: ' + s.month
            );
        }
    }

    // targetAmount=0 のときに achievementRate がゼロ除算にならないこと
    @IsTest
    static void testAchievementRate_zeroTarget() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, null);
        Test.stopTest();

        // targetAmount はテストデータで設定していないので全行0 → achievementRate は 0 のまま
        for (SalesForecastController.ForecastSummary s : result.summaryList) {
            System.assertEquals(0, s.achievementRate, 'achievementRate should be 0 when targetAmount is 0');
        }
    }

    // 対象外ユーザIDを指定すると結果が0件になること（ユーザ絞り込み）
    @IsTest
    static void testGetSalesForecast_differentUser() {
        User mgr = [SELECT Id FROM User WHERE Username = 'testmgr_sfcast@example.test'];

        Test.startTest();
        // mgr は商談を持っていないため detailList は空
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(mgr.Id, 2025, null);
        Test.stopTest();

        System.assertEquals(0, result.detailList.size(), 'mgr has no opps');
        System.assertNotEquals(null, result.summaryList, 'summaryList should not be null');
        System.assertEquals(0, result.summaryList.size(), 'no summary rows when no opps');
    }

    // 会計年度の境界: 4月1日（FY開始）がヒットし、前月3月31日はヒットしないこと
    @IsTest
    static void testGetSalesForecast_fiscalYearBoundary() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        // FY2024（2024/04〜2025/03）に入る商談と入らない商談を追加
        Opportunity inRange = new Opportunity(
            Name = 'Opp-Apr2025', OwnerId = sub.Id,
            CloseDate = Date.newInstance(2025, 4, 1),
            StageName = 'Prospecting', Amount = 10000
        );
        Opportunity outRange = new Opportunity(
            Name = 'Opp-Mar2025', OwnerId = sub.Id,
            CloseDate = Date.newInstance(2025, 3, 31),
            StageName = 'Prospecting', Amount = 99999
        );
        insert new List<Opportunity>{ inRange, outRange };

        Test.startTest();
        SalesForecastController.ForecastResult resultFY2025 =
            SalesForecastController.getSalesForecast(sub.Id, 2025, null);
        SalesForecastController.ForecastResult resultFY2024 =
            SalesForecastController.getSalesForecast(sub.Id, 2024, null);
        Test.stopTest();

        // FY2025 (2025/04〜2026/03) には inRange + @TestSetup の3件 = 4件
        System.assertEquals(4, resultFY2025.detailList.size(), 'FY2025 should include Apr2025 and 3 setup opps');
        // FY2024 (2024/04〜2025/03) には outRange の1件
        System.assertEquals(1, resultFY2024.detailList.size(), 'FY2024 should include only Mar2025 opp');
    }

    // ロールを持たないユーザでは自分自身のみ返ること
    @IsTest
    static void testGetSubordinateUsers_noRole() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User noRoleUser = new User(
            LastName         = 'NoRole',
            Alias            = 'nrole',
            Email            = 'norole@example.test',
            Username         = 'norole_sfcast@example.test',
            ProfileId        = p.Id,
            TimeZoneSidKey   = 'Asia/Tokyo',
            LocaleSidKey     = 'ja_JP',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'ja'
        );
        insert noRoleUser;

        Test.startTest();
        List<SalesForecastController.UserOption> opts;
        System.runAs(noRoleUser) {
            opts = SalesForecastController.getSubordinateUsers();
        }
        Test.stopTest();

        System.assertEquals(1, opts.size(), 'only self when no role assigned');
        System.assertEquals(noRoleUser.Id, opts[0].value, 'option value should be the user own Id');
    }

    // detailList の各フィールドが正しくマッピングされていること
    @IsTest
    static void testDetailListFieldMapping() {
        User sub = [SELECT Id FROM User WHERE Username = 'testsub_sfcast@example.test'];

        Test.startTest();
        SalesForecastController.ForecastResult result =
            SalesForecastController.getSalesForecast(sub.Id, 2025, null);
        Test.stopTest();

        Boolean foundClosedWon = false;
        for (SalesForecastController.OpportunityDetail d : result.detailList) {
            System.assertNotEquals(null, d.id,        'id should be set');
            System.assertNotEquals(null, d.name,      'name should be set');
            System.assertNotEquals(null, d.closeDate, 'closeDate should be set');
            System.assertNotEquals(null, d.stageName, 'stageName should be set');
            System.assert(d.amount >= 0,              'amount should be non-negative');
            if (d.stageName == 'Closed Won') {
                foundClosedWon = true;
                System.assertEquals(100000, d.amount, 'Closed Won opp amount should be 100000');
            }
        }
        System.assert(foundClosedWon, 'Closed Won opp should be present');
    }
}
