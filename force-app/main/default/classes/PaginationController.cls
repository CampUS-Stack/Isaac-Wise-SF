public with sharing class PaginationController {

    public list<Object> objects {get; set;}

    /// Set Wrapper Pagenation variables
    public Integer counter {get; set;}
    public Integer numberOfRecordsShown {get;set;}
    public Integer totalPages {get; set;}
    public Integer pageSize {get; set;}
    public Integer pageNumber {get; set;}

    public PaginationController(list<Object> objectsToSet) {
        if(objectsToSet == null){
            return;
        }

        this.counter = 0;
        this.totalPages = 1;
        this.pageNumber = 1;
        this.pageSize = 10;
        this.numberOfRecordsShown=10;
        this.objects = objectsToSet;
    }

    public list<Object> getObjectRecords(){

        list<Object> returnList = new list<Object>();
        try{
            for(integer counter2=(pageNumber-1)*pageSize;counter2<(Math.min(pageNumber*pageSize,objects.size()));counter2++){
                returnList.add(objects.get(counter2));
            }
        }
        catch(Exception ex){
            system.debug(ex.getLineNumber());
            system.debug(ex.getCause());
            system.debug(ex.getMessage());
        }

        return returnList;
    }

    public boolean getHasNext(){

        system.debug('Get has next running.');
        system.debug('Page Number ' + this.pageNumber);
        system.debug('Total Pages: ' + this.totalPages);
        Boolean returnBool = !(this.pageNumber == this.totalPages) && !(this.totalPages == 0 || this.totalPages == 1);
        system.debug('Return Bool: ' + returnBool);
        return returnBool;
    }

    public boolean getHasPrev(){

        return (this.pageNumber != 1);
    }

    public void nextButton(){

        this.pageNumber++;
    }

    public void prevButton(){

        this.pageNumber--;
    }

    public void firstButton(){

        this.pageNumber = 1;
    }

    public void lastButton(){

        this.pageNumber = this.totalPages;
    }

    public void setNumOfRecordsPerPage(){
        try{
            if((numberOfRecordsShown == null || numberOfRecordsShown == 0)){
                numberOfRecordsShown = 100;
                this.pageSize = numberOfRecordsShown;
            }else{
                this.pageSize = numberOfRecordsShown;
            }

            this.pageNumber = 1;
            setTotalPages();
        }
        catch(Exception ex){
            system.debug(ex.getLineNumber());
            system.debug(ex.getCause());
            system.debug(ex.getMessage());
        }
    }

    public void setTotalPages(){
        if(pageSize == null || this.objects == null){
            return;
        }

        this.totalPages = Integer.valueOf(Math.ceil(this.objects.size()/(Double)pageSize));
    }
}