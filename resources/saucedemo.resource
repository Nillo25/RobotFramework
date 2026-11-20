*** Settings ***
Documentation       Page-level keywords for Sauce Demo (https://www.saucedemo.com),
...                 a demo shop built by Sauce Labs for practising test automation.
...                 Selectors use the data-test attributes the site provides.
Library             Browser
Library             Collections


*** Variables ***
${SAUCE_URL}        https://www.saucedemo.com
${HEADLESS}         ${True}
${PASSWORD}         secret_sauce


*** Keywords ***
Start Browser
    New Browser    chromium    headless=${HEADLESS}
    Set Browser Timeout    10s

Open Sauce Demo
    [Documentation]    Fresh context per test: no cookies or cart left over from another test.
    New Context
    New Page    ${SAUCE_URL}

Login As
    [Arguments]    ${user}    ${password}=${PASSWORD}
    Fill Text    data-test=username    ${user}
    Fill Secret    data-test=password    $password
    Click    data-test=login-button

Products Page Should Be Open
    Get Text    data-test=title    ==    Products

Login Error Should Contain
    [Arguments]    ${text}
    Get Text    data-test=error    *=    ${text}

Add Item To Cart
    [Arguments]    ${item_id}
    Click    data-test=add-to-cart-${item_id}

Cart Badge Should Show
    [Arguments]    ${count}
    Get Text    data-test=shopping-cart-badge    ==    ${count}

Complete Checkout
    [Arguments]    ${first}=Test    ${last}=Robot    ${zip}=06100
    Click    data-test=shopping-cart-link
    Click    data-test=checkout
    Fill Text    data-test=firstName    ${first}
    Fill Text    data-test=lastName    ${last}
    Fill Text    data-test=postalCode    ${zip}
    Click    data-test=continue
    Click    data-test=finish

Order Should Be Complete
    Get Text    data-test=complete-header    ==    Thank you for your order!

Sort Products By
    [Documentation]    Values: az, za, lohi, hilo.
    [Arguments]    ${value}
    Select Options By    data-test=product-sort-container    value    ${value}

Prices Should Be Ascending
    ${elements}=    Get Elements    data-test=inventory-item-price
    ${prices}=    Create List
    FOR    ${element}    IN    @{elements}
        ${text}=    Get Text    ${element}
        Append To List    ${prices}    ${{ float($text.lstrip('$')) }}
    END
    ${sorted}=    Evaluate    sorted($prices)
    Lists Should Be Equal    ${prices}    ${sorted}
