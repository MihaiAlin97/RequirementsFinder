Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

#allow execution of unsigned scripts

# include files
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    .("$ScriptDirectory\Functions.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
Write-Host ("$ScriptDirectory\Functions.ps1")

#end include

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$ExcelFile=''##DOORS export
$SequenceFile=''
$ExcelPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\ExcelPaths.txt")
$SequencePaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\SequencePaths.txt")

$ExcelSearchResults=[System.Collections.ArrayList]@()##every result from Search-Sheet function is stored here

$syncHash = [hashtable]::Synchronized(@{})

#####
$syncHash.ExcelFile=$ExcelFile
$syncHash.SequenceFile=$SequenceFile
$syncHash.ExcelPaths=$ExcelPaths
$syncHash.SequencePaths=$SequencePaths
#####

$syncHash.SelectDOORSexportButtonWasClicked=$false
$syncHash.SelectuTasSequenceButtonWasClicked=$false
$syncHash.FindButtonWasClicked=$false
$syncHash.AddButtonWasClicked=$false


##this part is for adding textboxes in main
$syncHash.LastOYPosition=130##the y position for the textboxes;is incremented everytime the AddCheckBoxes function is called
$syncHash.TextBoxCounter=2##the current number of textboxes;incremented by 2 everytime the AddCheckBoxes function is called  
$syncHash.TextBoxList=[System.Collections.ArrayList]@()
##for adding textboxes
$syncHash.ScriptDirectory=$ScriptDirectory
$syncHash.Icon= New-Object System.Drawing.Icon("$ScriptDirectory\uTAS5_Sequence.ico")

$processRunspace =[runspacefactory]::CreateRunspace()
$processRunspace.ApartmentState = "STA"
$processRunspace.ThreadOptions = "ReuseThread"          
$processRunspace.Open()
##set available data for thread
$processRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    
##create powershell instance
##ui will run in another thread;when 'Generate Code' button will be clicked,it will set a variable outside the thread to true and it will start generating code
$ExecuteParallel= [PowerShell]::Create().AddScript({ 
    

    # include files
    $ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    try {
        .("$syncHash.ScriptDirectory\Functions.ps1")
    }
    catch {
        Write-Host "Error while loading supporting PowerShell Scripts" 
    }
    Write-Host ("$syncHash.ScriptDirectory\Functions.ps1")


    Add-Type -assembly System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $syncHash.ReqFinder             = New-Object System.Windows.Forms.Form
    $syncHash.ReqFinder.Text        ='Traceability Search'
    $syncHash.ReqFinder.Width       = 950
    $syncHash.ReqFinder.Height      = 300
    $syncHash.ReqFinder.MaximumSize = New-Object System.Drawing.Size(950, 300)
    $syncHash.ReqFinder.MinimumSize = New-Object System.Drawing.Size(950, 300)
    $syncHash.ReqFinder.Font         = 'Microsoft Sans Serif,10'
    $syncHash.ReqFinder.Icon         = $syncHash.Icon
    
    $syncHash.Label1                = New-Object System.Windows.Forms.Label
    $syncHash.Label1.Text           = "Start Req ID:"
    $syncHash.Label1.Location       = New-Object System.Drawing.Point(10,132)
    $syncHash.Label1.Font           = 'Microsoft Sans Serif,10'
 
    $syncHash.Label2                = New-Object System.Windows.Forms.Label
    $syncHash.Label2.Text           = "End Req ID:"
    $syncHash.Label2.Location       = New-Object System.Drawing.Point(210,132)
    $syncHash.Label2.Font           = 'Microsoft Sans Serif,10'


    $syncHash.TextBox1              = New-Object System.Windows.Forms.TextBox
    $syncHash.TextBox1.Location     = New-Object System.Drawing.Size(110,130)##x,y coordinates
    $syncHash.TextBox1.Size         = New-Object System.Drawing.Size(80,20)#marime
    $syncHash.TextBox1.Font         = 'Microsoft Sans Serif,10'

    $syncHash.TextBox2              = New-Object System.Windows.Forms.TextBox
    $syncHash.TextBox2.Location     = New-Object System.Drawing.Size(310,130)##x,y coordinates
    $syncHash.TextBox2.Size         = New-Object System.Drawing.Size(80,20)#marime
    $syncHash.TextBox2.Font         = 'Microsoft Sans Serif,10'


    $null                           = $syncHash.TextBoxList.Add($syncHash.TextBox1)
    $null                           = $syncHash.TextBoxList.Add($syncHash.TextBox2)



    $syncHash.ComboBox1             = New-Object System.Windows.Forms.ComboBox
    $syncHash.ComboBox1.Width       = 700
    $syncHash.ComboBox1.Location    = New-Object System.Drawing.Point(20,27)
    $syncHash.ComboBox1.Font        = 'Microsoft Sans Serif,8'
    $syncHash.ComboBox1.Items.AddRange([System.Collections.ArrayList]@($syncHash.ExcelPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
    $syncHash.ComboBox1.SelectedItem=$syncHash.ExcelPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)[0]    

    $syncHash.ComboBox2             = New-Object System.Windows.Forms.ComboBox
    $syncHash.ComboBox2.Width       = 700
    $syncHash.ComboBox2.Location    = New-Object System.Drawing.Point(20,87)
    $syncHash.ComboBox2.Font        = 'Microsoft Sans Serif,8'
    $syncHash.ComboBox2.Items.AddRange([System.Collections.ArrayList]@($syncHash.SequencePaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
    $syncHash.ComboBox2.SelectedItem=$syncHash.SequencePaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)[0]

    ##button for selecting path to excel file
    $syncHash.Button1               = New-Object System.Windows.Forms.Button
    $syncHash.Button1.Location      = New-Object System.Drawing.Size(750,25)
    $syncHash.Button1.Size          = New-Object System.Drawing.Size(150,23)
    $syncHash.Button1.Text          = "Select DOORS export"
    $syncHash.Button1.Font          = 'Microsoft Sans Serif,10'

    ##button for selecting path to .seq file
    $syncHash.Button2               = New-Object System.Windows.Forms.Button
    $syncHash.Button2.Location      = New-Object System.Drawing.Size(750,85)
    $syncHash.Button2.Size          = New-Object System.Drawing.Size(150,23)
    $syncHash.Button2.Text          = "Select uTas sequence"
    $syncHash.Button2.Font          = 'Microsoft Sans Serif,10'

    #calls Search-Sheet and Search-Sequence functions
    $syncHash.Button3               = New-Object System.Windows.Forms.Button
    $syncHash.Button3.Location      = New-Object System.Drawing.Size(420,130)
    $syncHash.Button3.Size          = New-Object System.Drawing.Size(45,23)
    $syncHash.Button3.Text          = "Find"
    $syncHash.Button3.Font          = 'Microsoft Sans Serif,10'

    $syncHash.Button4               = New-Object System.Windows.Forms.Button
    $syncHash.Button4.Location      = New-Object System.Drawing.Size(470,130)
    $syncHash.Button4.Size          = New-Object System.Drawing.Size(45,23)
    $syncHash.Button4.Text          = "Add"
    $syncHash.Button4.Font          = 'Microsoft Sans Serif,10'
    
    
    $syncHash.Button1.Add_Click({
        
        $syncHash.SelectDOORSexportButtonWasClicked=$true
        
    })
        
    $syncHash.Button2.Add_Click({
    
        $syncHash.SelectuTasSequenceButtonWasClicked=$true
        
    })
    
    $syncHash.Button3.Add_Click({
        $syncHash.ExcelFile=$syncHash.ComboBox1.Text;
        $syncHash.SequenceFile=$syncHash.ComboBox2.Text;
        
        $syncHash.FindButtonWasClicked=$true

    
    })
    $syncHash.Button4.Add_Click({
        If($global:syncHash.LastOYPosition -gt 950){return}
        $global:syncHash.LastOYPosition=$global:syncHash.LastOYPosition+30

        #first textbox in call
        $global:syncHash.TextBoxCounter=$global:syncHash.TextBoxCounter+1

        $syncHash.FirstTextBox = New-Object System.Windows.Forms.TextBox
        $syncHash.FirstTextBox.Location = New-Object System.Drawing.Size(110,$syncHash.LastOYPosition)##x,y coordinates
        $syncHash.FirstTextBox.Size = New-Object System.Drawing.Size(80,20)#marime
        
        New-Variable -Name "objTextBox$syncHash.TextBoxCounter" -Value $syncHash.FirstTextBox
        $global:syncHash.ReqFinder.Controls.Add($syncHash.FirstTextBox)
        $null =$syncHash.TextBoxList.Add($syncHash.FirstTextBox)



        ##second textbox in call
        $global:syncHash.TextBoxCounter=$global:syncHash.TextBoxCounter+1

        $syncHash.SecondTextBox = New-Object System.Windows.Forms.TextBox
        $syncHash.SecondTextBox.Location = New-Object System.Drawing.Size(310,$syncHash.LastOYPosition)##x,y coordinates
        $syncHash.SecondTextBox.Size = New-Object System.Drawing.Size(80,20)#marime


        New-Variable -Name "objTextBox$syncHash.TextBoxCounter" -Value $syncHash.SecondTextBox
        $global:syncHash.ReqFinder.Controls.Add($syncHash.SecondTextBox)
        $null =$syncHash.TextBoxList.Add($syncHash.SecondTextBox)


        If($global:syncHash.LastOYPosition -gt 240){
            $syncHash.FutureSize=$global:syncHash.ReqFinder.Height+30
            $global:syncHash.ReqFinder.MaximumSize = New-Object System.Drawing.Size(950,$syncHash.FutureSize)
            $global:syncHash.ReqFinder.MinimumSize = New-Object System.Drawing.Size(950,$syncHash.FutureSize)
            $global:syncHash.ReqFinder.Height+=30

        }
        
        
    })


    $syncHash.ReqFinder.Controls.AddRange(@($syncHash.Label1,$syncHash.Label2,$syncHash.ComboBox1,$syncHash.ComboBox2,$syncHash.Button1,$syncHash.Button2,$syncHash.Button3,$syncHash.Button4,$syncHash.TextBox1,$syncHash.TextBox2))
    
    
    
    $syncHash.ReqFinder.ShowDialog()
    
    sleep -s 1
    
    
    

})


  
$ExecuteParallel.Runspace = $processRunspace
##start thread(used to display form in a non-freezing manner

$Handle = $ExecuteParallel.BeginInvoke()
[System.Threading.Thread]::CurrentThread.GetApartmentState()

##execute main here
sleep -s 1

#Register-ObjectEvent -InputObject $syncHash.ReqFinder -EventName FormClosed -Action {UpdatePathInfo;stop-process -Id $PID;}



while($true){    

    
    if($syncHash.SelectDOORSexportButtonWasClicked -eq $true){
        
    
        
        ##clear items from ComboBox
        $syncHash.ComboBox1.Items.Clear()
            
        ##call SelectDocument;Couldn't do this inside add_click because all variables used should be available inside the runspace add_click is present;not necesarry for variables that don't interact with variables binded to thread
        SelectDocument -ExcelFile;
        
        Write-Host $ExcelFile
            
        ##copy text from authentic files to their equivalent in $syncHash in order to have the latest updated version in $syncHash
        $syncHash.ExcelPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\ExcelPaths.txt")
        $syncHash.ExcelFile=$ExcelFile
                        
        ##obtain the paths from file without empty lines   
        $syncHash.ComboBox1.Items.AddRange([System.Collections.ArrayList]@($syncHash.ExcelPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
            
        ##put selected file inside combobox
        $syncHash.ComboBox1.SelectedItem=$syncHash.ExcelFile;
    
    
        $syncHash.SelectDOORSexportButtonWasClicked=$false  
    }
    
    if($syncHash.SelectuTasSequenceButtonWasClicked -eq $true){
        ##clear items from ComboBox
        $syncHash.ComboBox2.Items.Clear()
            
        ##call SelectDocument;Couldn't do this inside add_click because all variables used should be available inside the runspace add_click is present;not necesarry for variables that don't interact with variables binded to thread
        SelectDocument -SequenceFile;
        
        Write-Host $SequenceFile
            
        ##copy text from authentic files to their equivalent in $syncHash in order to have the latest updated version in $syncHash
        $syncHash.SequencePaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\SequencePaths.txt")
        $syncHash.SequenceFile=$SequenceFile
                        
        ##obtain the paths from file without empty lines   
        $syncHash.ComboBox2.Items.AddRange([System.Collections.ArrayList]@($syncHash.SequencePaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
            
        ##put selected file inside combobox
        $syncHash.ComboBox2.SelectedItem=$syncHash.SequenceFile;
    
    
        $syncHash.SelectuTasSequenceButtonWasClicked=$false 
    
    
    }
    
    if($syncHash.FindButtonWasClicked -eq $true){
        DisableWindow  
        ##ensure files are correct
        ##check if both comboboxes have valid paths(ending in .seq and .DBC)
        if(($syncHash.SequenceFile -match "(.*\.seq)$")-eq $false -and ($syncHash.ExcelFile -match "(.*\.xlsx)$")-eq $false){
            DisplayPopUpWindow "The paths you entered do not point to a valid Excel worksheet,nor to a valid uTas 5+ Sequence!" "Invalid Excel and sequence files"     
            $syncHash.FindButtonWasClicked=$false
        }
                
        ##check if text provided inside combobox has extension .seq
        if(($syncHash.SequenceFile -match "(.*\.seq)$")-eq $false){
            DisplayPopUpWindow "The path you entered does not point to a valid uTas 5+ Sequence!" "Invalid sequence file"     
            $syncHash.FindButtonWasClicked=$false
        }
                
        ##check if text provided inside combobox has extension .DBC
        if(($syncHash.ExcelFile -match "(.*\.xlsx)$")-eq $false){
            DisplayPopUpWindow "The path you entered does not point to a valid Excel worksheet!" "Invalid Excel worksheet"
            $syncHash.FindButtonWasClicked=$false
        } 
        ##end
        
        
        
        
        $ExcelSearchResults=[System.Collections.ArrayList]@()

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        
        UpdatePathInfo
        
        ##for each pair of textboxes,call function Search-Sheet,which searches in doors excel file for requirements
        for($i=0;$i -le $syncHash.TextBoxList.Count;$i=$i+2){
            ShowProgress "Obtaining excel reqs"
            Search-Sheet -start $syncHash.TextBoxList[$i].Text -end $syncHash.TextBoxList[$i+1].Text -file $syncHash.ExcelFile;
            
        }
        
        
        Search-Sequence -file $syncHash.SequenceFile

        $stopwatch.Stop()
        Write-Host $stopwatch.Elapsed

        #Write-Host $ExcelSearchResults
        
        EnableWindow
        
        $syncHash.FindButtonWasClicked=$false
    }

}


$ExecuteParallel.EndInvoke($Handle)  
 
##close runspace
##it will happen only when x button is clicked
$processRunspace.Close()
$ExecuteParallel.Dispose()



