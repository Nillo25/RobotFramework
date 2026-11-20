*** Settings ***
Documentation       Reusable keywords for the Restful Booker API.
Library             RequestsLibrary
Library             Collections
Library             String


*** Variables ***
${BASE_URL}         https://restful-booker.herokuapp.com
${ADMIN_USER}       admin
${ADMIN_PASSWORD}   password123
&{JSON_HEADERS}     Content-Type=application/json    Accept=application/json


*** Keywords ***
Open Booker Session
    [Documentation]    Creates the "booker" session and fails fast if the API is down.
    # RequestsLibrary skips TLS verification by default (verify=False), so turn it on.
    Create Session    booker    ${BASE_URL}    headers=&{JSON_HEADERS}    verify=${True}
    ${status}    ${response}=    Run Keyword And Ignore Error
    ...    GET On Session    booker    /ping    expected_status=201    timeout=10
    IF    '${status}' == 'FAIL'
        Fail    Restful Booker is not reachable at ${BASE_URL}: ${response}
    END

Get Auth Token
    [Documentation]    Logs in as the admin user and returns the token.
    ${body}=    Create Dictionary    username=${ADMIN_USER}    password=${ADMIN_PASSWORD}
    ${response}=    POST On Session    booker    /auth    json=${body}    expected_status=200
    Dictionary Should Contain Key    ${response.json()}    token
    RETURN    ${response.json()}[token]

Build Booking Payload
    [Documentation]    Unique first name, so parallel users of the public API do not clash.
    ${suffix}=    Generate Random String    8    [LETTERS]
    ${dates}=    Create Dictionary    checkin=2026-12-01    checkout=2026-12-05
    ${payload}=    Create Dictionary
    ...    firstname=Test${suffix}
    ...    lastname=Robot
    ...    totalprice=${420}
    ...    depositpaid=${True}
    ...    bookingdates=${dates}
    ...    additionalneeds=Breakfast
    RETURN    ${payload}

Create Test Booking
    [Documentation]    Creates a booking and returns its id and the payload that was sent.
    ${payload}=    Build Booking Payload
    ${response}=    POST On Session    booker    /booking    json=${payload}    expected_status=200
    RETURN    ${response.json()}[bookingid]    ${payload}

Booking Should Match
    [Arguments]    ${booking_id}    ${expected}
    ${response}=    GET On Session    booker    /booking/${booking_id}    expected_status=200
    Dictionaries Should Be Equal    ${response.json()}    ${expected}

Token Headers
    [Arguments]    ${token}
    ${headers}=    Create Dictionary    Cookie=token=${token}    &{JSON_HEADERS}
    RETURN    ${headers}
