import ballerina/http;
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

# A service representing a network-accessible API
# bound to port `9090`.
service /portal on new http:Listener(9090) {

    resource function post employees/[string file](@http:Payload Employee[] employees) returns json|error? {
        blobs:BlobClient blobClient = check createStorageClient();
        return blobClient->putBlob(container, file, "BlockBlob", employees.toJsonString().toBytes());
    }
}

function createStorageClient() returns blobs:BlobClient|error {
    blobs:ConnectionConfig blobConnectionConfig = {accessKeyOrSAS: accessKey, accountName: account, authorizationMethod: "accessKey"};
    return check new (blobConnectionConfig);
}
