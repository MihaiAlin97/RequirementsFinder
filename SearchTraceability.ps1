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

$FileToGetValues=''##The excel file
$FileToSearchIn=''##The sequence file
$ExcelSearchResults=[System.Collections.ArrayList]@()##every result from Search-Sheet function is stored here
$LastOYPosition=130##the y position for the textboxes;is incremented everytime the AddCheckBoxes function is called
$TextBoxCounter=2##the current number of textboxes;incremented by 2 everytime the AddCheckBoxes function is called
$TextBoxList=[System.Collections.ArrayList]@()


Add-Type -assembly System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Main = New-Object System.Windows.Forms.Form
$Main.Text ='Traceability Search'
$Main.Width = 550
$Main.Height = 300
$Main.MaximumSize = New-Object System.Drawing.Size(550, 300)
$Main.MinimumSize = New-Object System.Drawing.Size(550, 300)

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Excel location:"
$Label1.Location  = New-Object System.Drawing.Point(10,30)

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Sequence path:"
$Label2.Location  = New-Object System.Drawing.Point(10,90)

$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = "Start Req ID:"
$Label3.Location  = New-Object System.Drawing.Point(10,130)

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Text = "End Req ID:"
$Label4.Location  = New-Object System.Drawing.Point(210,130)


$objTextBox1 = New-Object System.Windows.Forms.TextBox
$objTextBox1.Location = New-Object System.Drawing.Size(110,130)##x,y coordinates
$objTextBox1.Size = New-Object System.Drawing.Size(80,20)#marime

$objTextBox2 = New-Object System.Windows.Forms.TextBox
$objTextBox2.Location = New-Object System.Drawing.Size(310,130)##x,y coordinates
$objTextBox2.Size = New-Object System.Drawing.Size(80,20)#marime


$null =$TextBoxList.Add($objTextBox1)
$null =$TextBoxList.Add($objTextBox2)



$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.Width = 300
$ComboBox1.Location  = New-Object System.Drawing.Point(110,27)

$ComboBox2 = New-Object System.Windows.Forms.ComboBox
$ComboBox2.Width = 300
$ComboBox2.Location  = New-Object System.Drawing.Point(110,87)

##button for selecting path to excel file
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(420,25)
$Button1.Size = New-Object System.Drawing.Size(40,23)
$Button1.Text = "..."

##button for selecting path to .seq file
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Size(420,85)
$Button2.Size = New-Object System.Drawing.Size(40,23)
$Button2.Text = "..."

#calls Search-Sheet and Search-Sequence functions
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Location = New-Object System.Drawing.Size(420,125)
$Button3.Size = New-Object System.Drawing.Size(40,23)
$Button3.Text = "Find"

$Button4 = New-Object System.Windows.Forms.Button
$Button4.Location = New-Object System.Drawing.Size(460,125)
$Button4.Size = New-Object System.Drawing.Size(40,23)
$Button4.Text = "Add"

$Button1.Add_Click({SelectDocument -excel;$ComboBox1.Items.Add($FileToGetValues);$ComboBox1.SelectedItem=$FileToGetValues})
$Button2.Add_Click({SelectDocument -sequence;$ComboBox2.Items.Add($FileToSearchIn);$ComboBox2.SelectedItem=$FileToSearchIn})
$Button3.Add_Click({

$ExcelSearchResults=[System.Collections.ArrayList]@()

$stopwatch = New-Object System.Diagnostics.Stopwatch
$stopwatch.Start()

for($i=0;$i -lt $TextBoxList.Count;$i=$i+2){
Search-Sheet -start $TextBoxList[$i].Text -end $TextBoxList[$i+1].Text -file $FileToGetValues;

}

Search-Sequence -file $FileToSearchIn

$stopwatch.Stop()
Write-Host $stopwatch.Elapsed

Write-Host $ExcelSearchResults

#Search-Sequence -file $FileToSearchIn

})
$Button4.Add_Click({AddCheckBoxes;})



$Main.Controls.Add($Label1)
$Main.Controls.Add($Label2)
$Main.Controls.Add($Label3)
$Main.Controls.Add($Label4)
$Main.Controls.Add($ComboBox1)
$Main.Controls.Add($ComboBox2)
$Main.Controls.Add($Button1)
$Main.Controls.Add($Button2)
$Main.Controls.Add($Button3)
$Main.Controls.Add($Button4)
$Main.Controls.Add($objTextBox1)
$Main.Controls.Add($objTextBox2)
$Main.ShowDialog()
$Main.Focus()
