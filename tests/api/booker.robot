*** Settings ***
Documentation       API tests for Restful Booker (https://restful-booker.herokuapp.com),
...                 a public practice API. Each test creates its own booking,
...                 so it does not depend on data other people put there.
Resource            ../../resources/booker.resource
Suite Setup         Open Booker Session
Test Tags           api


*** Test Cases ***
Health Check Responds
    [Documentation]    Restful Booker answers /ping with 201, not 200. Known quirk of the app.
    [Tags]    smoke
    GET On Session    booker    /ping    expected_status=201

Created Booking Can Be Read Back
    [Tags]    smoke
    ${booking_id}    ${payload}=    Create Test Booking
    Booking Should Match    ${booking_id}    ${payload}

Admin Gets Auth Token
    [Tags]    regression
    ${token}=    Get Auth Token
    Should Not Be Empty    ${token}

Booking Can Be Updated With Token
    [Tags]    regression
    ${booking_id}    ${payload}=    Create Test Booking
    ${token}=    Get Auth Token
    ${headers}=    Token Headers    ${token}
    Set To Dictionary    ${payload}    totalprice=${999}    additionalneeds=Late checkout
    PUT On Session    booker    /booking/${booking_id}    json=${payload}    headers=${headers}
    ...    expected_status=200
    Booking Should Match    ${booking_id}    ${payload}

Update Without Token Is Forbidden
    [Tags]    regression
    ${booking_id}    ${payload}=    Create Test Booking
    Set To Dictionary    ${payload}    totalprice=${1}
    PUT On Session    booker    /booking/${booking_id}    json=${payload}    expected_status=403

Deleted Booking Is Gone
    [Documentation]    DELETE returns 201 Created instead of 200 or 204. Known quirk of the app.
    [Tags]    regression
    ${booking_id}    ${payload}=    Create Test Booking
    ${token}=    Get Auth Token
    ${headers}=    Token Headers    ${token}
    DELETE On Session    booker    /booking/${booking_id}    headers=${headers}    expected_status=201
    GET On Session    booker    /booking/${booking_id}    expected_status=404
