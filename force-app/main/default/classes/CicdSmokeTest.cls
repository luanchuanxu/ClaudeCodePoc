/**
 * CI/CD デプロイ検証用のスモークテスト用クラス。
 * GitHub Actions から agentDst 組織へのデプロイ経路が通ることを確認するための最小実装。
 */
public with sharing class CicdSmokeTest {
    public static String ping() {
        return 'pong';
    }
}
