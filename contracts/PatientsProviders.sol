pragma solidity ^0.4.17;

import './FuzzyMatcher.sol';

contract PatientsProviders {

    address admin;
    
    // A map of providers where key is code and value is provider struct
    mapping(string => Provider) private providers;

    // A map of patients where key is (hashed) full name and value is patient struct
    mapping(string => Patient) private patients;

    // FuzzyMatcher contract
    FuzzyMatcher fuzzyMatcher; 

    function PatientsProviders(address fuzzyMatcherAddress) public {
        admin = msg.sender;
        fuzzyMatcher = FuzzyMatcher(fuzzyMatcherAddress);
    }

    struct Provider {
        bool isActive;
        address providerAddress;
        mapping(string => address) records; // A map of records where key is patient full name and value is patient record address
    }

    struct Patient {
        bool isActive;
        string fullName; // Patient full name
        string[] historicalProviders; // An array of providers which hold records of this patient
        mapping(string => bool) isHistoricalProvider; // A map to flag if a providers has record of this patient of not. Key is provider code and value is the flag
    }

    /*
        Register a new patient with given full name. Also add this new name to fuzzy matcher.
    */
    function registerNewPatient(string fullName) {
        assert(!patients[fullName].isActive);
        patients[fullName] = Patient({ isActive: true, fullName: fullName, historicalProviders: new string[](0) });
        fuzzyMatcher.addNewNode(fullName);
    }

    /*
        Register a new provider. Only certain admin node could do so.
    */
    function registerNewProvider(string providerCode, address providerAddress) {
        require(msg.sender == admin);
        providers[providerCode] = Provider({ isActive: true, providerAddress: providerAddress });
    }

    /*
        Check if given full name has been registered as a patient
    */
    function isRegisteredPatient(string fullName) public returns(bool isRegistered) {
        return patients[fullName].isActive;
    }

    /*
        Check if given provider code has been registered as a provider
    */
    function isRegisteredProvider(string providerCode) public returns(bool isRegistered) {
        return providers[providerCode].isActive;
    }

    /*
        Associate given patient's record with given provider if the patient is new to the provider
    */
    function addPatientRecordToProvider(address recordAddress, string providerCode, string fullName, string pointer, bytes32 hashedRecord) public returns(bool success) {
        assert(!providerHasRecord(providerCode, fullName));
        assert(isRegisteredPatient(fullName));
        assert(isRegisteredProvider(providerCode));
        Patient patient = patients[fullName];
        patient.isHistoricalProvider[providerCode] = true;
        patient.historicalProviders.push(providerCode);
        patients[fullName] = patient;
        Provider provider = providers[providerCode];
        provider.records[fullName] = recordAddress;
    }

    /*
        Check if the given provider has any record of the patient with given full name
    */
    function providerHasRecord(string providerCode, string fullName) public returns(bool has) {
        assert(providers[providerCode].isActive);
        return providers[providerCode].records[fullName] != 0x0;
    }

    /*
        Get the record address from the given provider for a patient
    */
    function getPatientRecordAddressFromOneProvider(string providerCode, string fullName) public constant returns (address r) {
        return providers[providerCode].records[fullName];
    }

    /*
        Get a list of record address from all providers for a patient.
    */
    function getPatientRecordsFromAllProviders(string fullName) public constant returns (address[] r) {
        string[] memory historical = patients[fullName].historicalProviders;
        address[] memory results = new address[](historical.length);
        for (uint index = 0; index < historical.length; index++) {
            results[index] = providers[historical[index]].records[fullName];
        }
        return results;
    }
}
