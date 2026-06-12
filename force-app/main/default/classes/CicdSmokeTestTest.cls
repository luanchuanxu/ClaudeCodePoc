/**
 * CicdSmokeTest のテストクラス。
 * RunLocalTests 実行時にカバレッジを確保し、デプロイが通ることを保証する。
 */
@IsTest
private class CicdSmokeTestTest {
    @IsTest
    static void ping_returnsPong() {
        Test.startTest();
        String result = CicdSmokeTest.ping();
        Test.stopTest();

        System.assertEquals('pong', result, 'ping() は pong を返すべき');
    }
}
