public class CongrComm_MyEvents {

    Public List<Event_Participant__c > participants { get; set; }
    Public List<ParticipantsWrapper> participantsWrappers { get; set; }
    public boolean displayPopup { get; set; }
    Public List<Event_Participant__c > eventParticipants { get; set; }
    public String eventId { get; set; }
    public map<Id, Contact> contactMap { get; set; }

    private Contact currentUserContact;

    Public CongrComm_MyEvents() {

        contactMap = getContactMap();
        Date dateFilter = Date.today().addDays(-1);
        Date todayDate = Date.today();
        participants = [
                SELECT Id, Event_Participant__c.Contact__c, Event__c, Event__r.Name, Event__r.Event_Date_Start__c,
                        Event__r.Event_Date_End__c, Event__r.Description__c, Contact__r.Name, Chosen_Ticket_Type__c, Participant_Event_Fee__c
                FROM Event_Participant__c
                WHERE Contact__c in :contactMap.keySet()
                AND Event__r.Event_Date_End__c >= :date.today()
                ORDER BY Contact__r.Contact_Type__c, Event__r.Event_Date_Start__c ASC
        ];

        this.participantsWrappers = createParticipantsWrapper(contactMap, participants);
    }

    @TestVisible public list<ParticipantsWrapper> createParticipantsWrapper(map<Id, Contact> contacts, list<Event_Participant__c> participantsToCreate) {

        map<Id, ParticipantsWrapper> participantMap = new map<Id, ParticipantsWrapper>();
        for (Event_Participant__c curParticipants : participantsToCreate) {

            if (!contacts.containsKey(curParticipants.Contact__c)) {
                continue;
            }

            if (!participantMap.containsKey(curParticipants.Contact__c)) {
                participantMap.put(curParticipants.Contact__c, new ParticipantsWrapper());
            }

            ParticipantsWrapper pw = participantMap.get(curParticipants.Contact__c);
            pw.theContact = contacts.get(curParticipants.Contact__c);
            pw.theParticipants.add(curParticipants);

        }
        return participantMap.values();
    }

    @TestVisible public map<Id, Contact> getContactMap() {

        set<Id> returnSet = new set<Id>();

        String currentUserId = UserInfo.getUserId();
        returnSet.add(currentUserId);

        currentUserContact = UtilitiesUsers.GetContactForCommunityUser(currentUserId);

        try {
            map<Id, Contact> contact = new map<Id, Contact>([SELECT Id,Name FROM Contact WHERE AccountId = :currentUserContact.AccountId ORDER BY Contact_type__c ASC]);
            return contact;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    public class ParticipantsWrapper {

        public Contact theContact { get; set; }
        Public List<Event_Participant__c > theParticipants { get; set; }

        public ParticipantsWrapper() {
            theParticipants = new list<Event_Participant__c>();
        }
    }

}