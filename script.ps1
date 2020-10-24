$loc = "C:\Users\codel\OneDrive\Documents\Visual Studio Code Projects\html" #remove this later
cd $loc

$csvDirectory = "./csv/"

function Set-User {
    Write-Host "This is Adding a Employee to the list"
    $name = (Read-Host "Enter Name")
    $SSN =  (Read-Host "Enter Last 4 Digits of SSN")
    
    $address = (Read-Host "Enter Address without zip code or city").Replace(",",";")
    $addressRest = (Read-Host "Enter City and Zip Code")
    
    $hours = (Read-Host "Enter Total Hours Worked YTD")
    $rate = (Read-Host "Enter Normal Rate Pay")
    $pay = (Read-Host "Enter Total Pay YTD")
    
    $ohours =  (Read-Host "Enter Total Overtime Hours Worked YTD")
    $orate = (Read-Host "Enter Overtime Rate Pay")
    $opay = (Read-Host "Enter Total Overtime Pay YTD")

    $ytd_SSN = Read-Host "Enter the Total SSN PAY YTD"
    $ytd_FM = Read-Host "Enter the Total Federal Medicare PAY YTD"
    $ytd_FT = Read-Host "Enter the Total Federal Tax PAY YTD"

    $title = "SSN,Total Hours YTD,Pay Rate,Total Pay YTD,Overtime Hours YTD,Overtime Rate,Overtime Pay YTD,Address,Rest,YTD SSN,YTD Federal Medicare,YTD Federal Tax"
    $data = "$SSN,$hours,$rate,$pay,$ohours,$orate,$opay,$address,$addressRest,$ytd_SSN,$ytd_FM,$ytd_FT"
    Set-Content -Path "./csv/$name.csv" -Value $title,$data
}

function Get-User {
    $i = 0; Get-ChildItem $loc/csv | ForEach-Object{Write-Host "[$i] $_";$i++}
    $i = Read-Host "Select Employee"
    $file = ((Get-ChildItem ./csv)[$i]).Name
    return $file;
}

function Get-Money{
    param($money)
    $money = $money.Split(".")
    $money += "0";

    $ie = New-Object -com internetexplorer.application;
    $ie.navigate("https://www.tools4noobs.com/online_tools/number_spell_words/");
    while ($ie.Busy -eq $true) { Start-Sleep -Seconds 1; }

    $ie.Document.getElementById("number").value= $money[0]
    (($ie.Document.getElementsByClassName("btn btn-primary"))[0]).Click()
    Start-Sleep -Seconds 5;
    $dollars = $ie.Document.getElementsByClassName("well")[0].textContent

    $money[1] = ($money[1].PadRight(2,'0')).Substring(0,2)

    $ie.Quit()
    return "$dollars dollars and $money[1]/100 cents"
}

function Get-Taxes{
    param($money)
    $taxRate = 0.06;

    return $taxRate*$money
}

function GetMoney-String{
    param($money)
    $str = $money.ToString()
    $point = $str.IndexOf('.')
    $money = $str.Substring(0,$point+3)
    return 1*$money
}

$len = (Get-ChildItem ./csv).Length

if($len -eq 0)
{
    Set-User
}

$loop = $true;
$ie = 0;
while($loop)
{
    $input = Read-Host "Enter [0] Add,[1] Delete, [2] Print, [3] Exit"
    switch($input)
    {
        0{
            Set-User
        }
        1{
            echo "SELECT AN EMPLOYEE TO DELETE"
            $csvName = Get-User
            Remove-Item $loc/csv/$csvName
        }
        2{
            $csvName = Get-User
            $csv = Import-Csv .\csv\$csvName
            $startdate = Read-Host "Enter Start Date"
            $endDate = Read-Host "Enter End Date"
            $ftPay = Read-Host "Enter Federeal Tax Pay"

            $hours = 1*(Read-Host "Enter Hours worked")
            $csv.'Total Hours YTD' = ($hours)+$csv.'Total Hours YTD'
            $totalPay = $hours*$csv.'Pay Rate'
            $csv.'Total Pay YTD' = $totalPay + $csv.'Total Pay YTD'

            $ohours = 1*(Read-Host "Enter OverTime Hours worked")
            $csv.'Overtime Hours YTD'= ($ohours)+$csv.'Overtime Hours YTD'
            $totalOvertime = $ohours*$csv.'Overtime Rate'
            $csv.'Overtime Pay YTD' = $totalOvertime + $csv.'Overtime Pay YTD'

            $ssnPay = GetMoney-String ($paid * 0.062)
            $csv.'YTD SSN' = $ssnPay + $csv.'YTD SSN'
            $fmPay = GetMoney-String ($paid * 0.0145)
            $csv.'YTD Federal Medicare' = $fmPay + $csv.'YTD Federal Medicare'
            $csv.'YTD Federal Tax' = $ftPay + $csv.'YTD Federal Tax'
            $deduction = $ssnPay+$fmPay+$ftPay

            $paid = $totalPay+$totalOvertime
            $paidYTD = (1*$csv.'Total Pay YTD')+$csv.'Overtime Pay YTD'
            $date = Get-Date -Format MM/dd/yyyy

            $paycheck = (Get-Content .\html.html)
            $paycheck = $paycheck.Replace("NAME",$csvName.Replace(".csv","").ToUpper())
            $paycheck = $paycheck.Replace("COMBINE_PAY",$paid)
            $paycheck = $paycheck.Replace("COMBINE_PAY_MINUS_DEDUCTION",$paid-$deduction)
            $paycheck = $paycheck.Replace("MONEY_STR",($(Get-Money "$paid")).ToUpper())
            $paycheck = $paycheck.Replace("CUR_DATE",$date)
            $paycheck = $paycheck.Replace("ADRESS",$csv.Address)
            $paycheck = $paycheck.Replace("CITY",$csv.Rest)
            $paycheck = $paycheck.Replace("PB",$startdate)
            $paycheck = $paycheck.Replace("PE",$endDate)
            $paycheck = $paycheck.Replace("SSN",$csv.SSN)
            
            $paycheck = $paycheck.Replace("wHOURS",$hours)
            $paycheck = $paycheck.Replace("wRATE",$csv.'Pay Rate')
            $paycheck = $paycheck.Replace("wPAY",$totalPay)

            $paycheck = $paycheck.Replace("OHOURS",$ohours)
            $paycheck = $paycheck.Replace("ORATE",$csv.'Overtime Rate')
            $paycheck = $paycheck.Replace("OPAY",$totalOvertime)

            $paycheck = $paycheck.Replace("TOTAL_HOURS",$csv.'Total Hours YTD')
            $paycheck = $paycheck.Replace("TOTAL_PAYw",$csv.'Total Pay YTD')
            $paycheck = $paycheck.Replace("OVERTIME_HOURS",$csv.'Overtime Hours YTD')
            $paycheck = $paycheck.Replace("OVERTIME_TOTAL_PAY",$csv.'Overtime Pay YTD')

            

            $total = 1*$csv.'Overtime Pay YTD' + $csv.'Total Pay YTD'
            $paycheck = $paycheck.Replace("COMBINE_YTD_PAY",$total)

            Set-Content -Path ./paycheck.html $paycheck
            $ie = $ie = New-Object -com internetexplorer.application;
            $ie.navigate("$loc\paycheck.html");

            #set option to save before deleting the original file
            #$csv | Export-Csv -LiteralPath .\csv\$csvName
        }
        3{
            $loop = $false
        }
        default{"$input isn't what your supposed to put, put a value between 0 and 3"}
    }
}