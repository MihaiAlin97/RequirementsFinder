Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationClient.dll')
[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationTypes.dll')

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

##AutoIt for clicking on elements->too hard with win32 :))
Import-Module $ScriptDirectory\AutoItX.psd1 


Function AddCheckBoxes{
If($global:LastOYPosition -gt 950){return}
$global:LastOYPosition=$global:LastOYPosition+30

#first textbox in call
$global:TextBoxCounter=$global:TextBoxCounter+1

$FirstTextBox = New-Object System.Windows.Forms.TextBox
$FirstTextBox.Location = New-Object System.Drawing.Size(110,$LastOYPosition)##x,y coordinates
$FirstTextBox.Size = New-Object System.Drawing.Size(80,20)#marime

New-Variable -Name "objTextBox$TextBoxCounter" -Value $FirstTextBox 

$global:Main.Controls.Add($FirstTextBox)
$null =$global:TextBoxList.Add($FirstTextBox)



##second textbox in call
$global:TextBoxCounter=$global:TextBoxCounter+1

$SecondTextBox = New-Object System.Windows.Forms.TextBox
$SecondTextBox.Location = New-Object System.Drawing.Size(310,$LastOYPosition)##x,y coordinates
$SecondTextBox.Size = New-Object System.Drawing.Size(80,20)#marime

New-Variable -Name "objTextBox$TextBoxCounter" -Value $SecondTextBox
$global:Main.Controls.Add($SecondTextBox)
$null =$global:TextBoxList.Add($SecondTextBox)


If($global:LastOYPosition -gt 240){
$FutureSize=$global:Main.Height+30
$global:Main.MaximumSize = New-Object System.Drawing.Size(550,$FutureSize)
$global:Main.MinimumSize = New-Object System.Drawing.Size(550,$FutureSize)
$global:Main.Height+=30

}

}

Function SelectDocument{
##for excel and .seq

if($args[0].equals('-excel')){$type='ExcelWorkbook (*.xlsx)|*.xlsx'}
    
    elseif($args[0].equals('-sequence')){$type='SequenceFile (*.seq)|*.seq'}

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ ##open a windows file browser when '...' button is clicked
InitialDirectory = [Environment]::GetFolderPath('Desktop')
Filter=$type}
Write-Host $type
$null = $FileBrowser.ShowDialog()

if($args[0].equals('-excel')){$global:FileToGetValues = $FileBrowser.FileName}##check if '...' button is called to select an .xlsx or .seq file
elseif($args[0].equals('-sequence')){$global:FileToSearchIn = $FileBrowser.FileName}


}


Function Search-Sheet ##get cell values between a range of cell values
{ Param([String]$start,[String]$end,[String]$file)

if([string]::IsNullOrEmpty($start)){return}
if([string]::IsNullOrEmpty($end)){return}
if([string]::IsNullOrEmpty($file)){return}

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $False

$Workbook = $Excel.Workbooks.Open($file)

$Sheet=$Workbook.Sheets.item(1)

$CSVpath=$file.Substring(0,$file.Length-5)

$Sheet.SaveAs($CSVpath,6)




#|Where-Object {$_.OEM_ID_sv -match $start}

$CSVfile=Import-Csv ($CSVpath + ".csv") -Header "A","B","C","D" ,"E" ,"F" ,"G" 

$A=$CSVfile |Where-Object {$_.A -eq $start}|Select A
$B=$CSVfile |Where-Object {$_.B -eq $start}|Select B
$C=$CSVfile |Where-Object {$_.C -eq $start}|Select C
$D=$CSVfile |Where-Object {$_.D -eq $start}|Select D
$E=$CSVfile |Where-Object {$_.E -eq $start}|Select E
$F=$CSVfile |Where-Object {$_.F -eq $start}|Select F
$G=$CSVfile |Where-Object {$_.G -eq $start}|Select G


$Results=[System.Collections.ArrayList]@($A,$B,$C,$D,$E,$F,$G)

for($i=0;$i -lt $Results.Count;$i=$i+1){
if($Results[$i]){$Column=$Results[$i]}
}

$Column="$Column"[2]

$IntervalTrue=$false
foreach($line in $CSVfile){
    if($line.$Column -eq $start){$IntervalTrue=$true}##check if we reached the starting value
    
    if($IntervalTrue -eq $true){$null=$global:ExcelSearchResults.Add($line.$Column)}##if we are past starting value,we record everything
    
    if($line.$Column -eq $end){break}##if we reached the end value,we break

}


$Workbook.Close()
$Excel.Quit()
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)
[GC]::Collect()

Remove-Item -Path ($CSVpath + ".csv")

}



Function Search-Sequence{

Param([String]$file)

if([string]::IsNullOrEmpty($file)){return}##if .seq file not provided,do nothing
if($global:ExcelSearchResults.count -eq 0){return}##if there are no search results from excel file,do nothing

##start desired sequence
$SequenceProcess=[diagnostics.process]::Start($file)


##wait until process's window starts
while ($true){

if ($SequenceProcess.MainWindowHandle -ne 0)
   {
        break
   }
   
   Write-Host $SequenceProcess.MainWindowHandle
   $SequenceProcess.Refresh()

}
##maybe uTas will need time to load large files
Start-Sleep -s 30


##store the handle of the sequence's main window 
$SequenceProcessHandle=$SequenceProcess.MainWindowHandle


Write-Host $SequenceProcessHandle
$CurrentSequenceWindow=[System.Windows.Automation.AutomationElement]::FromHandle($SequenceProcessHandle)
$CurrentSequenceWindow.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
$CurrentSequenceWindow.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::AutomationIdProperty)
##obtain automation element from the previous handle

##the following conditions are used to reach the needed children
$condition1=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"EditSequenceCtrl")
$condition2=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"CodeAreaTab")
$condition3=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"MainProgram")




##here we split between test cases control tabs(those on left side,stacked on top of each other) and test cases description fields(objective,input,expected result,traceability)



#test cases control tabs
$condition4=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TestCasesControl")
$condition5=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"itemsDataGrid")
$condition6=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"GroupItem")
$condition7=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridRow")
$condition8=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridCell")
$condition9=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"TextBox")
#


#test case description
$condition10=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TestCaseDescription")
$condition11=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,"System.Windows.Controls.Label")
$condition12=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,"Item: System.Windows.Controls.Label, Column Display Index: 3")
$condition13=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TraceabilityTextBox")
#

$mainSearch=$CurrentSequenceWindow.FindFirst(2,$condition1)
$mainSearch=$mainSearch.FindFirst(2,$condition2)
$mainSearch=$mainSearch.FindFirst(2,$condition3)
#common for both


$TCsearch=$mainSearch.FindFirst(2,$condition4)
$TCsearch=$TCsearch.FindFirst(4,$condition5)


Write-Host "itemsDataGrid ---------------  " $TCsearch
Write-Host "itemsDataGrid counter should be one ---------------  " $TCsearch.Count

$Groups=$TCsearch.FindAll(2,$condition6)#GO UNTIL WE OBTAIN GROUPS(Setup,Emergenvy Stop,etc)


$TClist=[System.Collections.ArrayList]@()##Matched TC's

   
   Write-Host "Groups ---------------  " $Groups
   
 

for($i=0;$i -lt $Groups.Count;$i++){

   $ExpandCollapsePattern=$Groups[$i].GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
   $ExpandCollapsePattern.Collapse()
   
   $Groups=$TCsearch.FindAll(2,$condition6)#GO UNTIL WE OBTAIN GROUPS(Setup,Emergenvy Stop,etc)
   

   
   Write-Host "Group" $Groups[$i].GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
   Write-Host "Group counter" $Groups.Count
   
   
   
   
   $Rows=$Groups[$i].findAll(2,$condition7)
   ##got all rows from current group
   
   for($j=0;$j -lt $Rows.Count;$j++){
       
   
       Write-Host "   "$Rows[$j].findFirst(2,$condition8).GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
   
       $Invoke=$Rows[$j].findFirst(2,$condition8).GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
       $Invoke.Invoke()
       ##invoke the test case cell to change traceability window's content
   
       ##traceability obtain automation element
       $TraceabilitySearch=$mainSearch.FindFirst(2,$condition10)
       $TraceabilitySearch=$TraceabilitySearch.FindFirst(2,$condition11)
       $TraceabilitySearch=$TraceabilitySearch.FindFirst(2,$condition12)
       $TraceabilitySearch=$TraceabilitySearch.FindAll(2,$condition13)

       $TextPattern=$TraceabilitySearch[0].GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)

   
   
   
       $TraceabilityReqArray=[System.Collections.ArrayList]@($TextPattern.DocumentRange.GetText(-1) -split ",")
       ##Get contents of traceability,put them in array
   
       Write-Host "      " $TextPattern.DocumentRange.GetText(64)
       Write-Host "            " $TraceabilityReqArray[0] $TraceabilityReqArray.Count
   
       for($k=0;$k -lt $TraceabilityReqArray.Count;$k++){
       
           if(($global:ExcelSearchResults -contains $TraceabilityReqArray[$k]) -eq $true){
           
              $null =$TClist.Add($Rows[$j].findFirst(2,$condition8).GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty))
              
              #Add TC to TClist if it contains traceability from excel
           }
      }
   
   }
   
   
   
}


Write-Host "Matched test cases---------------------------"
for($i=0;$i -le $TClist.Count;$i++){
Write-Host $TClist[$i]
}
##conditions for obtaining different automation elements based on id or name or classname
$changeWindow=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"tbtEditTestStrategies")
$condition14=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"EditTestStrategiesControl1")
$condition15=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TestStrategiesDataGrid")
$condition16=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"GroupItem")
$condition17=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridRow")
$condition18=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridCell")

$condition19=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"TextBlock")
$condition20=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"CheckBox")

##set focus on uTas window if it is not in the foreground
$CurrentSequenceWindow.SetFocus()
Start-Sleep -s 2


$StrategiesButton=$CurrentSequenceWindow.FindFirst(2,$changeWindow)
$point=$StrategiesButton.GetClickablePoint()


Write-Host "Location of button" $point.X $point.Y

#click on Strategies button to change window
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y

Start-Sleep -s 2

$StrategiesSearch=$CurrentSequenceWindow.FindFirst(2,$condition14)
$StrategiesSearch=$StrategiesSearch.FindFirst(2,$condition15)
$Groups=$StrategiesSearch.FindAll(2,$condition16)


for($i=0;$i -lt $Groups.Count;$i++){
   $Groups=$StrategiesSearch.FindAll(2,$condition16)
   
   
   Write-Host "Groups Count Strategies ->>>>>>>>>>>>"  $Groups.Count
   Write-Host $Groups[$i].GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
   
   ##expand collapsed tc's in strategies
   $ExpandCollapsePattern=$Groups[$i].GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
   $ExpandCollapsePattern.Expand()
   
   
   
   $Rows=$Groups[$i].findAll(2,$condition17)
   ##got all rows from current group
   
   Write-Host "Displaying the checkboxes"
   
   for($j=0;$j -lt $Rows.Count;$j++){##here cells[0] represents the checkbox,cells[1] represents the name
   
   $Cells=$Rows[$j].findAll(2,$condition18)
   
   
   
   
   $TextBlock=$Cells[1].FindFirst(2,$condition19)##get name of the cell containing tc name
   $TextBlock=$TextBlock.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
   $Name=[System.Collections.ArrayList]@($TextBlock -split " ")
   $Name=$Name[0]
   
   if(($TClist -contains $Name) -eq $true){##activate checkboxes in case there is any match
   $CheckBox=$Cells[0].FindFirst(2,$condition20)##get tc check box
   $Toggle=$CheckBox.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
   $Toggle.Toggle()
   Write-Host $Name
   }
   
   }
   
   ##collapse tc's in strategies -> to get all GroupItems in Strategies
   
   $ExpandCollapsePattern=$Groups[$i].GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
   $ExpandCollapsePattern.Collapse()
   
   
   
}

for($i=0;$i -lt $Groups.Count;$i++){
##expand again to help user
 $ExpandCollapsePattern=$Groups[$i].GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
 $ExpandCollapsePattern.Expand()
}

[threading.thread]::CurrentThread.GetApartmentState()

$MessageBody = "Testcases have been checked in uTAS"
$MessageTitle = "Search Done"
$ButtonType = [System.Windows.MessageBoxButton]::OK
$MessageIcon = [System.Windows.MessageBoxImage]::Information

$MessageBoxOptions = [System.Windows.MessageBoxOptions]::DefaultDesktopOnly
 
$Result=[System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon,0,$MessageBoxOptions)


}

