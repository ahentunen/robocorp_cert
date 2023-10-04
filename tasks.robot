*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${download_url}     https://robotsparebinindustries.com/orders.csv
${system_url}       https://robotsparebinindustries.com/#/robot-order


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website

    ${orders}=    Get Orders    ${download_url}
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the annoying modal
        Wait Until Keyword Succeeds
        ...    5x
        ...    1s
        ...    Fill the form    ${order}
    END
    Create ZIP package from PDF Files
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders
    [Arguments]    ${download_url}
    Download    ${download_url}    overwrite=${True}
    ${order_csv}=    Read Table From CSV    orders.csv    header=True
    RETURN    ${order_csv}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    css:input.form-control    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview
    Click Button    id:order
    ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt from html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt from html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}images${/}image_${order}.png
    RETURN    ${OUTPUT_DIR}${/}images${/}image_${order}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Save Pdf    ${pdf}
    Close All Pdfs

Create ZIP package from PDF Files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Close the browser
    Close Browser
