*** Settings ***
Documentation       UI tests for Sauce Demo with the Browser library (Playwright).
Resource            ../../resources/saucedemo.resource
Suite Setup         Start Browser
Suite Teardown      Close Browser    ALL
Test Setup          Open Sauce Demo
Test Teardown       Close Context
Test Tags           ui


*** Test Cases ***
Standard User Can Log In
    [Tags]    smoke
    Login As    standard_user
    Products Page Should Be Open

Locked Out User Sees Error
    [Tags]    regression
    Login As    locked_out_user
    Login Error Should Contain    Sorry, this user has been locked out.

Wrong Password Is Rejected
    [Tags]    regression
    Login As    standard_user    password=wrong_password
    Login Error Should Contain    Username and password do not match

Cart Badge Counts Added Items
    [Tags]    regression
    Login As    standard_user
    Add Item To Cart    sauce-labs-backpack
    Add Item To Cart    sauce-labs-bike-light
    Cart Badge Should Show    2

User Can Complete Checkout
    [Tags]    smoke
    Login As    standard_user
    Add Item To Cart    sauce-labs-backpack
    Complete Checkout
    Order Should Be Complete

Products Sort By Price Low To High
    [Tags]    regression
    Login As    standard_user
    Sort Products By    lohi
    Prices Should Be Ascending
