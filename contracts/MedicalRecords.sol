pragma solidity ^0.4.17;

import './PatientsProviders.sol';

contract MedicalRecords {

    address admin;
    mapping(address => Record) private records; // A map of records where key is record address and value is record struct
    mapping(uint => uint32) private historicalTotalStaying; // A map for historical staying data where key is the date timestamp and value is number of staying
    uint32 private currentTotalStaying; // current total number of patient staying in hospital
    uint lastRecordedDate;
    PatientsProviders patientsProviders;

    function MedicalRecords(address patientsProvidersAddress) public {
        admin = msg.sender;
        patientsProviders = PatientsProviders(patientsProvidersAddress);
    }

    struct Record {
        bool isActive;
        address providerAddress; // From which address this record is created
        uint32 version; // version number
        bytes32 hashedRecord; // sha256 of full records from the provider
        string pointer; // A remote address to access patient's full records in provider's database
    }

    /*
        Calculate the unix timestamp for today GTM 12:00 AM 
    */
    function getCurrentDate() view private returns (uint date) {
        return uint(now) / 60 / 60 / 24;
    }

    /*
        Get the number of staying patients for a given date
    */
    function getStayingForDate(uint date) view public returns (uint32 staying) {
        uint currentDate = getCurrentDate();
        if (date < currentDate && historicalTotalStaying[date] != 0) {
            return historicalTotalStaying[date]; 
        } else {
            return currentTotalStaying;
        }
    }

    /*
        Check if a record exist given a record address
    */
    function doesRecordExist(address recordAddress) view public returns (bool exist) {
        return records[recordAddress].isActive;
    }

    /*
        Get record struct by its address if the record exist
    */
    function getRecordByAddress(address recordAddress) view public returns (Record r) {
        assert(records[recordAddress].isActive);
        return records[recordAddress]; 
    }

    /*
        Admit a new patient
     */
    function admitPatient(string fullName) public {
        if (patientsProviders.isRegisteredPatient(fullName)) {
            patientsProviders.registerNewPatient(fullName);
        }
        increaseStaying();
    }

    /*
        Discharge a patient
    */
    function dischargePatient(string fullName) public {
        assert(patientsProviders.isRegisteredPatient(fullName));
        decreaseStaying(); 
    }

    /*
        Private: Increment the current staying number by 1. Update the lastRecordDate to now.
    */
    function increaseStaying() private {
        require(currentTotalStaying + 1 > currentTotalStaying);
        uint currentDate = getCurrentDate();
        // If lastRecordDate is not now, it means the number of staying keeps the same recently. We'll need to backfill the data from now back to lastRecordedDate.
        if (lastRecordedDate < currentDate) {
            for (uint date = lastRecordedDate; date < currentDate; date += 60 * 60 * 24) {
                historicalTotalStaying[date] = currentTotalStaying;
            }
            lastRecordedDate = currentDate;
        }
        currentTotalStaying++;
        historicalTotalStaying[currentDate] = currentTotalStaying;
    }

    /*
        Private: Decrement the current staying number by 1.
    */
    function decreaseStaying() private {
        require(currentTotalStaying > 0);
        currentTotalStaying--;
        historicalTotalStaying[getCurrentDate()] = currentTotalStaying;
    }

    /*
        Given some record meta data and an randonly address generated by client, create a record struc
    */
    function createPatientRecord(address recordAddress, string providerCode, string fullName, string pointer, bytes32 hashedRecord) public {
        require(!doesRecordExist(recordAddress));
        patientsProviders.addPatientRecordToProvider(recordAddress, providerCode, fullName, pointer, hashedRecord);
        createRecord(recordAddress, pointer, hashedRecord);
    }

    /*
        Given some record meta data and the record address, update a record struct
    */
    function updatePatientRecord(address recordAddress, string providerCode, string fullName, string pointer, bytes32 hashedRecord) public {
        require(doesRecordExist(recordAddress));
        require(patientsProviders.providerHasRecord(providerCode, fullName));
        updateRecord(recordAddress, pointer, hashedRecord);
    }

    /*
        Private: create record struct
    */
    function createRecord(address recordAddress, string pointer, bytes32 hashedRecord) private {
        Record storage record = records[recordAddress];
        require(!record.isActive);
        // Only the owner of the record could update it
        record.isActive = true;
        record.providerAddress = tx.origin;
        record.pointer = pointer;
        record.hashedRecord = hashedRecord;
        record.version = 1;
        records[recordAddress] = record;
    }

    /*
        Private: update record struct 
    */
    function updateRecord(address recordAddress, string pointer, bytes32 hashedRecord) private {
        Record storage record = records[recordAddress];
        require(record.isActive);
        // Only the owner of the record could update it
        require(tx.origin == record.providerAddress);
        record.pointer = pointer;
        record.hashedRecord = hashedRecord;
        record.version = record.version + 1;
        records[recordAddress] = record;
    }
}
