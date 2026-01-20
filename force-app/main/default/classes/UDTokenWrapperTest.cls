/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDTokenWrapperTest {

    public testMethod static void testCommentEndPoint1() {
        UDTokenWrapper udTokenWr = new UDTokenWrapper();
        udTokenWr.access_token = 'test';
        udTokenWr.instance_url = 'test';
        udTokenWr.id = 'test';
        udTokenWr.token_type = 'test';
        udTokenWr.issued_at = 'test';
        udTokenWr.signature = 'test';

        UDTokenWrapper.parse(JSON.serialize(udTokenWr));
    }

}