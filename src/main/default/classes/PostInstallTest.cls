@isTest
private class PostInstallTest {
    static testmethod void testInstallScript() {

       PostInstall postinstall = new PostInstall();
       Test.testInstall(postinstall, new Version(1,57));

  }
}