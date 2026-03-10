#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 [file join [file dirname [info script]] ..]]
# puts stderr $auto_path
package require pdf4tcl

pdf4tcl::new p1 -orient 0 -compress false -paper a4

# Page 1: All form types overview
p1 startPage
p1 setFont 16 "Helvetica-Bold"
p1 text "Form Fields Overview" -x 50 -y 780

p1 setFont 10 "Helvetica"

# --- Text (existing) ---
p1 text "Text:" -x 50 -y 740
p1 rectangle 150 730 200 20
p1 addForm text 150 730 200 20 -id name

p1 text "Text with init:" -x 50 -y 710
p1 rectangle 150 700 200 20
p1 addForm text 150 700 200 20 -id city -init "Stockholm"

p1 text "Multiline:" -x 50 -y 680
p1 rectangle 150 620 200 80
p1 addForm text 150 620 200 80 -id notes -multiline 1

# --- Password (new) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Password" -x 50 -y 590
p1 setFont 10 "Helvetica"

p1 text "Password:" -x 50 -y 570
p1 rectangle 150 560 200 20
p1 addForm password 150 560 200 20 -id pw

p1 text "PIN (init):" -x 50 -y 540
p1 rectangle 150 530 80 20
p1 addForm password 150 530 80 20 -id pin -init "1234"

# --- Checkbutton (existing) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Checkbutton" -x 50 -y 500
p1 setFont 10 "Helvetica"

p1 rectangle 150 480 20 20
p1 addForm checkbutton 150 480 20 20 -id cb1
p1 text "Unchecked" -x 180 -y 490

p1 rectangle 300 480 20 20
p1 addForm checkbutton 300 480 20 20 -id cb2 -init 1
p1 text "Checked" -x 330 -y 490

# --- Combobox (new) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Combobox" -x 50 -y 450
p1 setFont 10 "Helvetica"

p1 text "Color:" -x 50 -y 430
p1 rectangle 150 420 150 20
p1 addForm combobox 150 420 150 20 -id color \
    -options {"Red" "Green" "Blue" "Yellow"} -init "Red"

p1 text "Editable:" -x 50 -y 400
p1 rectangle 150 390 200 20
p1 addForm combobox 150 390 200 20 -id custom \
    -options {"Option A" "Option B" "Option C"} -editable 1

p1 text "Sorted:" -x 50 -y 370
p1 rectangle 150 360 150 20
p1 addForm combobox 150 360 150 20 -id sorted \
    -options {"Cherry" "Apple" "Banana"} -sort 1

# --- Listbox (new) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Listbox" -x 50 -y 330
p1 setFont 10 "Helvetica"

p1 text "Single:" -x 50 -y 310
p1 rectangle 150 250 150 80
p1 addForm listbox 150 250 150 80 -id fruit \
    -options {"Apple" "Banana" "Cherry" "Date" "Elderberry" "Fig"}

p1 text "Multi:" -x 50 -y 220
p1 rectangle 150 170 150 70
p1 addForm listbox 150 170 150 70 -id multi \
    -options {"Alpha" "Beta" "Gamma" "Delta" "Epsilon"} \
    -multiselect 1

# --- Radiobutton (new) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Radiobutton" -x 50 -y 140
p1 setFont 10 "Helvetica"

p1 text "Size:" -x 50 -y 120
p1 rectangle 150 108 14 14
p1 addForm radiobutton 150 108 14 14 -group size -value Small -init 1
p1 text "Small" -x 170 -y 118
p1 rectangle 220 108 14 14
p1 addForm radiobutton 220 108 14 14 -group size -value Medium
p1 text "Medium" -x 240 -y 118
p1 rectangle 300 108 14 14
p1 addForm radiobutton 300 108 14 14 -group size -value Large
p1 text "Large" -x 320 -y 118

p1 text "Priority:" -x 50 -y 90
p1 rectangle 150 78 14 14
p1 addForm radiobutton 150 78 14 14 -group prio -value Low
p1 text "Low" -x 170 -y 88
p1 rectangle 220 78 14 14
p1 addForm radiobutton 220 78 14 14 -group prio -value Normal -init 1
p1 text "Normal" -x 240 -y 88
p1 rectangle 300 78 14 14
p1 addForm radiobutton 300 78 14 14 -group prio -value High
p1 text "High" -x 320 -y 88

# --- Pushbutton (new) ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Pushbutton" -x 50 -y 55
p1 setFont 10 "Helvetica"

p1 addForm pushbutton 150 30 80 22 -id btnReset \
    -caption "Reset" -action reset
p1 addForm pushbutton 240 30 100 22 -id btnURL \
    -caption "Website" -action url -url "https://example.com"
p1 addForm pushbutton 350 30 80 22 -id btnSubmit \
    -caption "Submit" -action submit -url "https://example.com/post"

# Page 1b: Signature and ReadOnly overview
p1 startPage
p1 setFont 16 "Helvetica-Bold"
p1 text "Signature & ReadOnly Fields" -x 50 -y 780

p1 setFont 10 "Helvetica"

# --- Signature ---
p1 setFont 12 "Helvetica-Bold"
p1 text "Signature" -x 50 -y 740
p1 setFont 10 "Helvetica"

p1 text "Basic:" -x 50 -y 710
p1 addForm signature 150 680 250 50 -id sigBasic

p1 text "With label:" -x 50 -y 650
p1 addForm signature 150 620 250 50 -id sigLabeled \
    -label "Unterschrift Auftraggeber"

p1 text "ReadOnly:" -x 50 -y 590
p1 addForm signature 150 560 250 50 -id sigLocked -readonly 1

# --- ReadOnly demo ---
p1 setFont 12 "Helvetica-Bold"
p1 text "ReadOnly Fields" -x 50 -y 530
p1 setFont 10 "Helvetica"

p1 text "Text (ro):" -x 50 -y 505
p1 rectangle 150 495 200 20
p1 addForm text 150 495 200 20 -id roText -init "Cannot edit" -readonly 1

p1 text "Combo (ro):" -x 50 -y 475
p1 addForm combobox 150 465 150 20 -id roCombo \
    -options {"Fixed" "Locked"} -init "Fixed" -readonly 1

p1 text "Checkbox (ro):" -x 50 -y 445
p1 addForm checkbox 150 435 14 14 -id roCheck -init 1 -readonly 1
p1 text "(checked, locked)" -x 170 -y 445

# Page 2: Practical form example with signature and readonly
p1 startPage
p1 setFont 14 "Helvetica-Bold"
p1 text "Registration Form" -x 50 -y 780

p1 setStrokeColor 0 0 0
p1 setLineWidth 0.5
p1 line 50 770 545 770
p1 setFont 10 "Helvetica"

# Personal information
p1 setFont 11 "Helvetica-Bold"
p1 text "Personal Information" -x 50 -y 748

p1 setFont 10 "Helvetica"
p1 text "Title:" -x 70 -y 720
p1 addForm combobox 160 710 120 20 -id title \
    -options {"Mr" "Mrs" "Ms" "Dr" "Prof"}

p1 text "First name:" -x 70 -y 690
p1 rectangle 160 680 180 20
p1 addForm text 160 680 180 20 -id firstname

p1 text "Last name:" -x 70 -y 660
p1 rectangle 160 650 180 20
p1 addForm text 160 650 180 20 -id lastname

p1 text "Password:" -x 70 -y 630
p1 rectangle 160 620 180 20
p1 addForm password 160 620 180 20 -id regpassword

# Read-only fields (pre-filled, not editable)
p1 setFont 11 "Helvetica-Bold"
p1 text "Account Info (read-only)" -x 50 -y 590

p1 setFont 10 "Helvetica"
p1 text "Account #:" -x 70 -y 565
p1 rectangle 160 555 180 20
p1 addForm text 160 555 180 20 -id acctno -init "ACC-2026-0042" -readonly 1

p1 text "Status:" -x 70 -y 535
p1 addForm combobox 160 525 120 20 -id status \
    -options {"Active" "Inactive" "Pending"} -init "Active" -readonly 1

# Using "checkbox" alias
p1 text "Verified:" -x 70 -y 505
p1 addForm checkbox 160 498 14 14 -id verified -init 1 -readonly 1
p1 text "Yes" -x 180 -y 505

# Contact preference
p1 setFont 11 "Helvetica-Bold"
p1 text "Contact Preference" -x 50 -y 470

p1 setFont 10 "Helvetica"
p1 text "Preferred:" -x 70 -y 445
p1 addForm radiobutton 160 435 12 12 -group contact -value Email -init 1
p1 text "Email" -x 178 -y 445
p1 addForm radiobutton 240 435 12 12 -group contact -value Phone
p1 text "Phone" -x 258 -y 445
p1 addForm radiobutton 320 435 12 12 -group contact -value Mail
p1 text "Mail" -x 338 -y 445

# Interests
p1 setFont 11 "Helvetica-Bold"
p1 text "Interests" -x 50 -y 410

p1 setFont 10 "Helvetica"
p1 text "Topics:" -x 70 -y 390
p1 addForm listbox 160 320 200 90 -id interests \
    -options {"Technology" "Science" "Art" "Music" "Sports" "Travel" "Food"} \
    -multiselect 1

# Agreement
p1 addForm checkbutton 70 290 14 14 -id agree
p1 text "I agree to the terms and conditions" -x 90 -y 300

p1 addForm checkbutton 70 265 14 14 -id newsletter
p1 text "Subscribe to newsletter" -x 90 -y 275

# --- Signature (new) ---
p1 setFont 11 "Helvetica-Bold"
p1 text "Signature" -x 50 -y 235

p1 setFont 10 "Helvetica"
p1 text "Applicant:" -x 70 -y 212
p1 addForm signature 160 180 250 50 -id sigApplicant \
    -label "Sign here"

p1 text "Date:" -x 70 -y 168
p1 rectangle 160 158 120 20
p1 addForm text 160 158 120 20 -id sigDate

# Buttons
p1 addForm pushbutton 160 120 100 24 -id regReset \
    -caption "Clear Form" -action reset
p1 addForm pushbutton 280 120 100 24 -id regSubmit \
    -caption "Register" -action submit -url "https://example.com/register"

p1 write -file test7.pdf
p1 destroy
