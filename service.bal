import ballerina/http;
import ballerina/xmldata;
import ballerinax/azure_storage_service.blobs;

configurable string accessKey = ?;
configurable string account = ?;
configurable string container = ?;

type Address record {
    string streetaddress;
    string city;
    string state;
    string postalcode;
};

type Personal record {
    string firstname;
    string lastname;
    string gender;
    int birthyear;
    Address address;
};

type Employee record {
    string empid;
    Personal personal;
};

type Location record {
    string street;
    string zip;
};

type OutputEmployee record {
    string empid;
    string name;
    int birth;
    string city;
    Location location;
};

# A service representing a network-accessible API
# bound to port `9090`.
service /portal on new http:Listener(9090) {

    resource function post employees/[string file](@http:Payload Employee[] employees) returns json|error? {
        blobs:BlobClient blobClient = check createStorageClient();
        return blobClient->putBlob(container, file, "BlockBlob", employees.toJsonString().toBytes());
    }

    resource function get employees(@http:Header string accept, string file) returns json|xml|http:NotAcceptable|error {
        blobs:BlobClient blobClient = check createStorageClient();
        blobs:BlobResult result = check blobClient->getBlob(container, file);
        string jsonData = check string:fromBytes(result.blobContent);
        match accept {
            "application/json" => {
                return jsonData.fromJsonString();
            }
            "application/xml" => {
                return check xmldata:fromJson(check jsonData.fromJsonString());
            }
            _ => {
                return http:NOT_ACCEPTABLE;
            }
        }
    }

    resource function get convert(string file) returns OutputEmployee[]|error {
        blobs:BlobClient blobClient = check createStorageClient();
        blobs:BlobResult result = check blobClient->getBlob(container, file);
        string jsonData = check string:fromBytes(result.blobContent);
        json jsonVal = check jsonData.fromJsonString();
        Employee[] inputEmployee = checkpanic jsonVal.cloneWithType();
        OutputEmployee[] outputData = transform(inputEmployee);
        return outputData;
    }
}

function transform(Employee[] employee) returns OutputEmployee[] => from var employeeItem in employee
    select {
        empid: employeeItem.empid,
        name: employeeItem.personal.firstname + " " + employeeItem.personal.lastname,
        birth: employeeItem.personal.birthyear,
        city: employeeItem.personal.address.city,
        location: {
            street: employeeItem.personal.address.streetaddress,
            zip: employeeItem.personal.address.postalcode
        }
    };

function createStorageClient() returns blobs:BlobClient|error {
    blobs:ConnectionConfig blobConnectionConfig = {accessKeyOrSAS: accessKey, accountName: account, authorizationMethod: "accessKey"};
    return check new (blobConnectionConfig);
}
