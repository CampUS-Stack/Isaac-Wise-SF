/**
 * Created by Kritik Garg on 01-08-2019.
 */

global class HebrewDateCalculationControllerTest implements HttpCalloutMock  {

    global HTTPResponse respond(HTTPRequest req)
    {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"gy":2020,"gm":5,"gd":25,"hy":5780,"hm":"Sivan","hd":2,"hebrew":"\u05d1\u05f3 \u05d1\u05bc\u05b0\u05e1\u05b4\u05d9\u05d5\u05b8\u05df \u05ea\u05e9\u05f4\u05e4","events":["46th day of the Omer"]}');
        res.setStatusCode(200);
        return res;
    }
}