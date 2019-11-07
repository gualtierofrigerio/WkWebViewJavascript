var testDictionary = {"key1" : "value1&value1b", "key2" : [{"key3" : "€", "key4" : "menù", "key5" : "a?b"}]};
var urlPrefix = "nativeapp://";

function initPage(parameter) {
    if (parameter) {
        return "OK";
    }
    return "KO";
}

function test(stringParameter, number, dictionary) {
    console.log("test");
    alert(stringParameter);
    return "OK";
}

function sendMessage() {
    window.webkit.messageHandlers.nativeapp.postMessage({paramter1 : "value1", parameter2 : "value2"})
}

function sendParameters() {
    window.location = urlPrefix + "parameters?parameter1=100&parameter2=200&parameter3=abcd";
}

function sendJSON() {
    var dictionary = {"key1" : "value1&value1b", "key2" : [{"key3" : "€", "key4" : "menù", "key5" : "a?b"}]};
    window.webkit.messageHandlers.nativeApp.postMessage({message : testDictionary});
}

function sendJSONURL() {
    window.location = urlPrefix + "message=" + encodeURIComponent(JSON.stringify(testDictionary));
}

function sendBase64() {
    window.location = urlPrefix + btoa(encodeURIComponent(JSON.stringify(testDictionary)));
}
