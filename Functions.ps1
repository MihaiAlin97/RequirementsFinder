Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationClient.dll')
[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationTypes.dll')

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

##AutoIt for clicking on elements->too hard with win32 :))
Import-Module $ScriptDirectory\AutoItX.psd1 


Function AddCheckBoxes{
If($global:syncHash.LastOYPosition -gt 950){return}
$global:syncHash.LastOYPosition=$global:syncHash.LastOYPosition+30

#first textbox in call
$global:syncHash.TextBoxCounter=$global:syncHash.TextBoxCounter+1

$syncHash.FirstTextBox = New-Object System.Windows.Forms.TextBox
$syncHash.FirstTextBox.Location = New-Object System.Drawing.Size(110,$syncHash.LastOYPosition)##x,y coordinates
$syncHash.FirstTextBox.Size = New-Object System.Drawing.Size(80,20)#marime


$syncHash.FirstTextBox=$FirstTextBox
$global:syncHash.ReqFinder.Controls.Add($syncHash.FirstTextBox)
$null =$global:syncHash.TextBoxList.Add($syncHash.FirstTextBox)



##second textbox in call
$global:syncHash.TextBoxCounter=$global:syncHash.TextBoxCounter+1

$SecondTextBox = New-Object System.Windows.Forms.TextBox
$SecondTextBox.Location = New-Object System.Drawing.Size(310,$syncHash.LastOYPosition)##x,y coordinates
$SecondTextBox.Size = New-Object System.Drawing.Size(80,20)#marime

New-Variable -Name "objTextBox$syncHash.TextBoxCounter" -Value $SecondTextBox
$syncHash.SecondTextBox=$SecondTextBox
$global:syncHash.ReqFinder.Controls.Add($syncHash.SecondTextBox)
$null =$global:syncHash.TextBoxList.Add($syncHash.SecondTextBox)


If($global:syncHash.LastOYPosition -gt 240){
    $syncHash.FutureSize=$global:syncHash.ReqFinder.Height+30
    $global:syncHash.ReqFinder.MaximumSize = New-Object System.Drawing.Size(950,$syncHash.FutureSize)
    $global:syncHash.ReqFinder.MinimumSize = New-Object System.Drawing.Size(950,$syncHash.FutureSize)
    $global:syncHash.ReqFinder.Height+=30

}

}

Function SelectDocument{
    ##for signals and .seq

    if($args[0].equals('-SequenceFile')){
        $type='uTAS 5+ Sequence (*.seq)|*.seq';
        $LastDirectory=Split-Path -Path ($global:SequencePaths -split "`r`n")[0] -Parent
        }
        
    elseif($args[0].equals('-ExcelFile')){
        $type='Microsoft Excel Worksheet (*.xlsx)|*.xlsx';
        $LastDirectory=Split-Path -Path ($global:ExcelPaths -split "`r`n")[0] -Parent
        }

    Add-Type -AssemblyName System.Windows.Forms
    Write-Host $LastDirectory;
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ ##open a windows file browser when 'Select #file' button is clicked
        RestoreDirectory=$false;
        InitialDirectory=$LastDirectory;
        Filter=$type;
    }

    ##Write-Host $type
    $null = $FileBrowser.ShowDialog()

    if($args[0].equals('-SequenceFile')){
        ##if no file was selected in file dialog,return
        if([string]::IsNullOrEmpty($FileBrowser.FileName)){return}
        
        ##set file containing signals to what was selected in File dialog
        $global:SequenceFile = $FileBrowser.FileName;
        
        ##check if last selected file's path is contained in the paths file(SignalsPaths.txt);if it is contained replace it with "" and add last selected file's path to the beggining of file
        
        if($global:SequencePaths -like ("*"+$FileBrowser.FileName+"`r`n*")){
            $CurrentPath=$FileBrowser.FileName
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:SequencePaths=$global:SequencePaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append selected file path to what is contained in the paths file
        $global:SequencePaths=($FileBrowser.FileName+"`r`n"+$global:SequencePaths)
        
        #create a new paths file containing updated infos
        $global:SequencePaths|Out-File "$ScriptDirectory\Paths\SequencePaths.txt" -width 1000
        
        #Write-Host $global:SequencePaths
    }##check if 'Select #file' button is called to select a .seq file
    
    elseif($args[0].equals('-ExcelFile')){
        ##if no file was selected in file dialog,return
        if([string]::IsNullOrEmpty($FileBrowser.FileName)){return}
        
        ##set file containing signals to what was selected in File dialog
        $global:ExcelFile = $FileBrowser.FileName;
        
        ##check if last selected file's path is contained in the paths file(ExcelPaths.txt);if it is contained replace it with "" and add last selected file's path to the beggining of file
        
        if($global:ExcelPaths -like ("*"+$FileBrowser.FileName+"`r`n*")){
            $CurrentPath=$FileBrowser.FileName
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:ExcelPaths=$global:ExcelPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append selected file path to what is contained in the paths file
        $global:ExcelPaths=($FileBrowser.FileName+"`r`n"+$global:ExcelPaths)
        
        #create a new paths file containing updated info
        $global:ExcelPaths|Out-File "$ScriptDirectory\Paths\ExcelPaths.txt" -width 1000
        #Write-Host $global:SignalsPaths
    }##check if 'Select #file' button is called to select a .DBC file


    


}


Function Search-Sheet ##get cell values between a range of cell values
{ Param([String]$start,[String]$end,[String]$file)
Write-Host $start
Write-Host $end
Write-Host $file
if([string]::IsNullOrEmpty($start)){return}
if([string]::IsNullOrEmpty($end)){return}
if([string]::IsNullOrEmpty($file)){return}

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $False

$Workbook = $Excel.Workbooks.Open($file)

$Sheet=$Workbook.Sheets.item(1)

$CSVpath=("$ScriptDirectory/DOORSCSV"+[guid]::NewGuid())

$Sheet.SaveAs($CSVpath,6)




#|Where-Object {$_.OEM_ID_sv -match $start}

$CSVfile=Import-Csv ($CSVpath + ".csv") -Header "A","B","C","D" ,"E" ,"F" ,"G" 
###only one column will be non null
$A=$CSVfile |Where-Object {$_.A -eq $start}|Select A
$B=$CSVfile |Where-Object {$_.B -eq $start}|Select B
$C=$CSVfile |Where-Object {$_.C -eq $start}|Select C
$D=$CSVfile |Where-Object {$_.D -eq $start}|Select D
$E=$CSVfile |Where-Object {$_.E -eq $start}|Select E
$F=$CSVfile |Where-Object {$_.F -eq $start}|Select F
$G=$CSVfile |Where-Object {$_.G -eq $start}|Select G
##store the columns of the doors excel file as elements in array
$Results=[System.Collections.ArrayList]@($A,$B,$C,$D,$E,$F,$G)

##for each element(column)check if it exists;if exists,store it in column
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
if($IntervalTrue -eq $false){DisplayPopUpWindow "One or more of the items you entered for searching are not present in DOORS export,or maybe you reversed the items by accident" "Values not found"}

$Workbook.Close()
$Excel.Quit()
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)


[GC]::Collect()

Remove-Item -Path ($CSVpath + ".csv")

#Write-Host "<------------------------Excel Search Results"
#Write-Host $global:ExcelSearchResults
#Write-Host "Excel Search Results------------------------>"
}



Function Search-Sequence{


Param([String]$file)

if([string]::IsNullOrEmpty($file)){return}##if .seq file not provided,do nothing
if($global:ExcelSearchResults.count -eq 0){return}##if there are no search results from excel file,do nothing

##start desired sequence
$SequenceProcess=[diagnostics.process]::Start($file)

#obtain TC id and traceability from xml seq
$TClist=[System.Collections.ArrayList]@()##Matched TC's
$CheckedTClist=[System.Collections.ArrayList]@()##Checks TCs inside Strategies

##start threads to search in sequence which of the excel results are contained in tcs


$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 1)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = @()

##scriptblock
$ScriptBlock={
    Param (
        [xml]$Sequence,
        [System.Collections.ArrayList]$ExcelSearchResults,
        [System.Collections.ArrayList]$TClist,
        [int]$begin,
        [int]$end   
    )

    
     
    for($i=$begin;$i -le $end;$i=$i+1){
    
        ##xml structure for testcases
        ##SEQ->TCs->TC->ID
        ##            ->DT->LNK->V
        #Write-Output "$i-------------------"    
        #Write-Output "`n"   
        #Write-Output "   " $Sequence.SEQ.TCs.TC[$i].ID
        
        $TraceabilityReqArray=[System.Collections.ArrayList]@()
        
        
        
        for($j = 0; $j -lt $Sequence.SEQ.TCs.TC[$i].DT.LNK.Count  ; $j = $j +1 ){
            
            #Write-Output "<Multi LNK" $Sequence.SEQ.TCs.TC[$i].DT.LNK[$j].V "Multi LNK>"
            
            $null=$TraceabilityReqArray.Add([string]$Sequence.SEQ.TCs.TC[$i].DT.LNK[$j].V)
          
            
        
        }
        
        #Write-Output "<Single LNK " $Sequence.SEQ.TCs.TC[$i].DT.LNK.V " Single LNK>"
        $null=$TraceabilityReqArray.Add([string]$Sequence.SEQ.TCs.TC[$i].DT.LNK.V)
        
        $MatchExists=$false
        
        for($k=0;$k -lt $TraceabilityReqArray.Count;$k++){
       
           
               if(($ExcelSearchResults -contains $TraceabilityReqArray[$k]) -eq $true){
               
                  $MatchExists=$true
                  
                  #Add TC to TClist if it contains traceability from excel
               }
               
               if($MatchExists -eq $true){ $null =$TClist.Add([string]($Sequence.SEQ.TCs.TC[$i].ID)) }
        
       }
   
    }
   
    
    Write-Output "$TClist"
    
    
    
}
##scriptblock ends here



[xml]$Sequence=Get-Content -Path $file
##progress bar initial settings


if($Sequence.SEQ.TCs.TC.Count -le 100){[int]$step=10}
else{[int]$step=100}

$NumberOfBlocks=[int]($Sequence.SEQ.TCs.TC.Count/$step)
$TCCount=[int]$Sequence.SEQ.TCs.TC.Count

$ProgressValue=0
$ProgressMaximum=100
$ProgressStep=(100/($Sequence.SEQ.TCs.TC.Count+1+$NumberOfBlocks+1))
[int]$Fin=1

Write-Host $NumberOfBlocks
[int]$myspecialvar=0
for($i=0;$i -le $NumberOfBlocks;$i=$i+1){
    Write-Host "------- Created thread no $i -------"
    Write-Host "Number of threads is " ($NumberOfBlocks+1)
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($ScriptBlock)
    $null = $runspace.AddArgument($Sequence)
    $null = $runspace.AddArgument($global:ExcelSearchResults)
    $null = $runspace.AddArgument([System.Collections.ArrayList]@())
    if($i -ne $NumberOfBlocks){
        $begin=[int]($i*$step)
        $end=[int](($i+1)*$step)
        $null = $runspace.AddArgument($begin)
        $null = $runspace.AddArgument($end)
        
        Write-Host "begin is $begin"
        Write-Host "end is $end"
        Write-Host "File : $Sequence"
    }
    else{
        $begin=[int]($i*$step)
        $end=[int]($TCCount)
        $null = $runspace.AddArgument($begin)
        $null = $runspace.AddArgument($end)
        
        Write-Host "begin is $begin"
        Write-Host "end is $end"
        Write-Host "File : $Sequence"
    }
        
    $runspace.RunspacePool = $pool
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
    
}



foreach ($runspace in $runspaces ) {
    ##be sure thread finished
    ##kind of ugly;each thread has max 100 tcs to verify,so its good
    
    while ($runspace.Status.IsCompleted -notcontains $true){}
    
    $ProgressValue=$ProgressValue+$ProgressStep
    if($ProgressValue -gt ($Fin+0.5)){
        [int]$Fin=$ProgressValue
        ShowProgress "$Fin % - Matching TCs"
    }
    
    
    
    # EndInvoke method retrieves the results of the asynchronous call
    $result=$runspace.Pipe.EndInvoke($runspace.Status)
    $result=$result -split '\s+'
    for($i=0;$i -lt $result.Count;$i=$i+1){
        $null=$TClist.Add($result[$i])
    }
    $runspace.Pipe.Dispose()
}

$pool.Close()
$pool.Dispose()


##threads end here;results ready



Write-Host "Matched test cases---------------------------"
for($i=0;$i -le $TClist.Count;$i++){
    Write-Host $TClist[$i] "`n" 
    Write-Host $TClist[$i].Length
}
Write-Host "Matched test cases---------------------------"


##wait until window started
while($true){
    ##Obtain uTas elements until Setup
    ##check if GroupItem(First->"Setup")is loaded->if so,the uTas window has fully loaded
    $SequenceProcess.Refresh()
    $CurrentSequenceWindow=[System.Windows.Automation.AutomationElement]::FromHandle($SequenceProcess.MainWindowHandle)


    $SearchDown1=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"EditSequenceCtrl")
    $SearchDown2=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"CodeAreaTab")
    $SearchDown3=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"MainProgram")
    $SearchDown4=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TestCasesControl")
    $SearchDown5=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"itemsDataGrid")
    $SearchDown6=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"GroupItem")


    $Setup=$CurrentSequenceWindow.FindFirst(2,$SearchDown1)
    $Setup=$Setup.FindFirst(2,$SearchDown2)
    $Setup=$Setup.FindFirst(2,$SearchDown3)
    $Setup=$Setup.FindFirst(2,$SearchDown4)
    $Setup=$Setup.FindFirst(2,$SearchDown5)
    $Setup=$Setup.FindFirst(2,$SearchDown6)

    Write-Host $Setup.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
    if($Setup.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty) -ne $null){break;}
}

Write-Host "Window loaded and ready"
Show-AU3WinActivate $SequenceProcess.MainWindowHandle
##done;at this moment the window should have loaded all controls and data


##store the handle of the sequence's main window 
$SequenceProcessHandle=$SequenceProcess.MainWindowHandle


Write-Host $SequenceProcessHandle

##obtain automation element from the previous handle
$CurrentSequenceWindow=[System.Windows.Automation.AutomationElement]::FromHandle($SequenceProcessHandle)
$CurrentSequenceWindow.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
$CurrentSequenceWindow.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::AutomationIdProperty)

##maximize window
$MainWindowPattern=$CurrentSequenceWindow.GetCurrentPattern([System.Windows.Automation.WindowPattern]::Pattern)
$MainWindowPattern.SetWindowVisualState(1)

##the following conditions are used to reach the needed children
$condition1=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"EditSequenceCtrl")
$condition2=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"CodeAreaTab")
$condition3=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"MainProgram")

$condition4=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"tbtEditTestStrategies")
$condition5=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"EditTestStrategiesControl1")
$condition6=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,"TestStrategiesDataGrid")
$condition7=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"GroupItem")
$condition8=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridRow")
$condition9=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"DataGridCell")

$condition10=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"TextBlock")
$condition11=New-Object Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty,"CheckBox")

##bring window to foreground 

Show-AU3WinActivate $SequenceProcess.MainWindowHandle

Start-Sleep -s 2


$StrategiesButton=$CurrentSequenceWindow.FindFirst(2,$condition4)
$point=$StrategiesButton.GetClickablePoint()


Write-Host "Location of button" $point.X $point.Y

#click on Strategies button to change window
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y
Invoke-AU3MouseClick -Button "left" -X $point.X -Y $point.Y

Start-Sleep -s 2


$StrategiesSearch=$CurrentSequenceWindow.FindFirst(2,$condition5)
$StrategiesSearch=$StrategiesSearch.FindFirst(2,$condition6)
$Groups=$StrategiesSearch.FindAll(2,$condition7)

#justtesting treewalker
$GroupWalker=New-Object Windows.Automation.TreeWalker($condition7)
Write-Host "Treeeeeeeeeeeee Walker"


       
        Write-Host "Displaying the checkboxes"
        
        $RowWalker=New-Object Windows.Automation.TreeWalker($condition8)
        $Row=$RowWalker.GetFirstChild($StrategiesSearch)
        $StrategiesCount=0
        while($Row -ne $null){
        ##here cells[0] represents the checkbox,cells[1] represents the name
            
            $ProgressValue=$ProgressValue+$ProgressStep
            if($ProgressValue -gt ($Fin+0.5)){
                [int]$Fin=$ProgressValue
                ShowProgress "$Fin % - Toggling TCs"
            }
            if($ProgressValue -gt 98.5){ShowProgress "100 % - Done "}
            
            $StrategiesCount=$StrategiesCount+1
            
            ##scroll to be able to get all rows->when too many of them,TreeWalker won't get next sibling if is out of window  at a very large distance
            if($StrategiesCount -gt 50){
                $Scroll=$StrategiesSearch.GetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern)
                $Scroll.ScrollVertical(4)
                $Scroll.ScrollVertical(4)
            }
                                                
            $Cells=$Row.findAll(2,$condition9)
            
            $WindowCoords=Get-AU3WinClientSize $SequenceProcess.MainWindowHandle
            $CheckboxCoords=$Cells[0].GetClickablePoint()
            
            Write-Host $WindowCoords
            Write-Host $CheckboxCoords
            if($CheckboxCoords.Y -le (1.7*$WindowCoords.Height/10) -and $StrategiesCount -gt 50){
            Write-Host "Adjusting height"
                while($CheckboxCoords.Y -le (8.5*$WindowCoords.Height/10)){
                    $Scroll=$StrategiesSearch.GetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern)
                    $Scroll.ScrollVertical(1)
                    $Scroll.ScrollVertical(1)
                    $Scroll.ScrollVertical(1)
                    $CheckboxCoords=$Cells[0].GetClickablePoint()
                    Write-Host "    "$WindowCoords
                    Write-Host "    "$CheckboxCoords
                    
                }
                Write-Host "Done adjusting height"
            }
           
            $TextBlock=$Cells[1].FindFirst(2,$condition10)##get name of the cell containing tc name
            $TextBlock=$TextBlock.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty)
            $Name=[System.Collections.ArrayList]@($TextBlock -split " ")
            $Name=$Name[0]
            
            
            Write-Host "At " $Name
            if($Name -match 'cleanup'){ break }
            Write-Host ($TClist -contains $Name)
            Write-Host $Name $Name.Length
            if(($TClist -contains $Name) -eq $true){##activate checkboxes in case there is any match
                $CheckBox=$Cells[0].FindFirst(2,$condition11)##get tc check box
                $Toggle=$CheckBox.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
                $Toggle.Toggle()
                Write-Host "$Name contains traceability from DoorsExport"
                $null=$CheckedTClist.Add($Name)
            }
                    
            
                      
            $Row=$RowWalker.GetNextSibling($Row)
            
            
       }

    

Write-Host "Treeeeeeeeeeeee Walker"

[string]$date=(Get-Date -UFormat "%d-%m-%Y-%H_%M_%S")
$file1=($ScriptDirectory+"\DebugLogs\ActuallyCheckedTCS"+$date+".txt")
$file2=($ScriptDirectory+"\DebugLogs\ExcelToSequenceMappings"+$date+".txt")

New-Item $file1 -ItemType file
New-Item $file2 -ItemType file
$write1=[System.IO.StreamWriter] $file1
$write2=[System.IO.StreamWriter] $file2

for($i=0;$i -le $CheckedTClist.Count;$i++){
    $write1.WriteLine($CheckedTClist[$i])
}
$write1.close()
$TClist=$TClist| select -uniq
for($i=0;$i -le $TClist.Count;$i++){
    $write2.WriteLine($TClist[$i])
}
$write2.close()
ShowProgress "100 % - Done "
[threading.thread]::CurrentThread.GetApartmentState()
Show-AU3WinActivate $SequenceProcess.MainWindowHandle
ShowProgress "100 % - Done "


$MessageBoxOptions = [System.Windows.MessageBoxOptions]::DefaultDesktopOnly
ShowProgress "100 % - Done " 
DisplayPopUpWindow "Testcases have been checked in uTAS.To be sure about validity of the search,Look into /DebugLogs and compare the two txt's" "Search Done."
ShowProgress "100 % - Done " 

}

function ShowProgress{
    Param([string]$text)
    Add-Type -AssemblyName System.Drawing
    
    $DesktopHandle=Get-AU3WinHandle "dwm.exe"
    $Graphics=[System.Drawing.Graphics]::FromHwnd($DesktopHandle)
    
    $TaskbarColor=[System.Drawing.Color]::FromArgb(25,30,34)
    $GreenColor=[System.Drawing.Color]::FromArgb(0,255,0)
    
    $TaskbarPen=[System.Drawing.Pen]($TaskbarColor)
    $TaskbarPen.Width=1
    $GreenPen=[System.Drawing.Pen]($GreenColor)
    
    $TaskbarBrush = New-Object System.Drawing.SolidBrush($TaskbarColor)
    $GreenBrush = New-Object System.Drawing.SolidBrush($GreenColor)
    
    
    $Rectangle=New-Object System.Drawing.Rectangle(1160,1043,1000,40)
    $Point=New-Object System.Drawing.Point(1450,1062.5)
    
    $Font = New-Object System.Drawing.Font("Arial", 30, "Regular","Pixel")
    $Format = [System.Drawing.StringFormat]::GenericDefault
    $Format.Alignment = [System.Drawing.StringAlignment]::Center
    $Format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $WordPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $WordPath.AddString($text,[System.Drawing.FontFamily]$Font.FontFamily,[int]$Font.Style,[int]$Font.Size,[System.Drawing.Point]$Point,[System.Drawing.StringFormat]$Format)

    $Graphics.DrawRectangle($TaskbarPen,$Rectangle)
    $Graphics.FillRectangle($TaskbarBrush,$Rectangle)

    $Graphics.DrawPath($GreenPen,$WordPath)
    $Graphics.FillPath($GreenBrush,$WordPath)
    
}

Function UpdatePathInfo{

##add excel paths to paths file->for edited file paths;not for selected from dialog files
        
        if($global:ExcelPaths -like ("*"+$global:syncHash.ComboBox1.Text+"`r`n*")){
            $CurrentPath=$global:syncHash.ComboBox1.Text
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:ExcelPaths=$global:ExcelPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append edited file path to what is contained in the paths file
        $global:ExcelPaths=($global:syncHash.ComboBox1.Text+"`r`n"+$global:ExcelPaths)
        
        #create a new paths file containing updated info
        $global:ExcelPaths|Out-File "$ScriptDirectory\Paths\ExcelPaths.txt" -width 1000
        
        ##
        
        
        ##add sequence paths to paths file->for edited file paths;not for selected from dialog files
        
        if($global:SequencePaths -like ("*"+$global:syncHash.ComboBox2.Text+"`r`n*")){
            $CurrentPath=$global:syncHash.ComboBox2.Text
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:SequencePaths=$global:SequencePaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append edited file path to what is contained in the paths file
        $global:SequencePaths=($global:syncHash.ComboBox2.Text+"`r`n"+$global:SequencePaths)
        
        #create a new paths file containing updated info
        $global:SequencePaths|Out-File "$ScriptDirectory\Paths\SequencePaths.txt" -width 1000
        


}


Function DisplayPopUpWindow{   
        $ButtonType = 0 ##OK
        $MessageIcon = 64 ##Information
        $Result=[System.Windows.Forms.MessageBox]::Show($args[0],$args[1],$ButtonType,$MessageIcon)
        $handle=Get-AU3WinHandle $args[1]
        Show-AU3WinActivate $handle
}


Function EnableWindow{
        $global:syncHash.Button1.Enabled=$true
        $global:syncHash.Button2.Enabled=$true
        $global:syncHash.Button3.Enabled=$true
        $global:syncHash.Button4.Enabled=$true
        $global:syncHash.TextBox1.Enabled=$true
        $global:syncHash.TextBox2.Enabled=$true  
        $global:syncHash.ComboBox1.Enabled=$true
        $global:syncHash.ComboBox2.Enabled=$true
}


Function DisableWindow{
        $global:syncHash.Button1.Enabled=$false
        $global:syncHash.Button2.Enabled=$false
        $global:syncHash.Button3.Enabled=$false
        $global:syncHash.Button4.Enabled=$false
        $global:syncHash.TextBox1.Enabled=$false
        $global:syncHash.TextBox2.Enabled=$false  
        $global:syncHash.ComboBox1.Enabled=$false
        $global:syncHash.ComboBox2.Enabled=$false
}

