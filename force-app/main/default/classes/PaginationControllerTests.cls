@isTest
private class PaginationControllerTests {

    @isTest static void ProcessTestCoverageForPaginationController() {
        PaginationController pc = new PaginationController(new list<Object>());
        pc.counter = 1;
        pc.numberOfRecordsShown = 1;
        pc.totalPages = 1;
        pc.pageSize = 10;
        pc.pageNumber = 1;
        pc.getHasPrev();
        pc.getHasNext();
        pc.nextButton();
        pc.prevButton();
        pc.firstButton();
        pc.lastButton();
        pc.setNumOfRecordsPerPage();
        pc.getObjectRecords();
        pc.setTotalPages();

    }

    @isTest static void test_method_two() {
        // Implement test code
    }

}