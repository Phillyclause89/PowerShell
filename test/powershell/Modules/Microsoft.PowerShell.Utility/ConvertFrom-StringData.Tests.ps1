# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
Describe "ConvertFrom-StringData DRT Unit Tests" -Tags "CI" {
    It "Should able to throw error when convert invalid line" {
        $str =@"
#comments here
abc
#comments here
def=content of def
"@
        { ConvertFrom-StringData $str } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
    }
}

Describe "ConvertFrom-StringData" -Tags "CI" {
    $sampleData = @'
foo  = 0
bar  = 1
bazz = 2
'@

    It "Should not throw when called with just the stringdata switch" {
	{ ConvertFrom-StringData -StringData 'a=b' } | Should -Not -Throw
    }

    It "Should return a hashtable" {
	$result = ConvertFrom-StringData -StringData 'a=b'
    $result | Should -BeOfType Hashtable
    }

    It "Should throw if not in x=y format" {
	{ ConvertFrom-StringData -StringData 'ab' }  | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
	{ ConvertFrom-StringData -StringData 'a,b' } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
	{ ConvertFrom-StringData -StringData 'a b' } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
	{ ConvertFrom-StringData -StringData 'a\tb' } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
	{ ConvertFrom-StringData -StringData 'a:b' } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ConvertFromStringDataCommand"
    }

    It "Should return the data on the left side in the key" {
	$actualValue = ConvertFrom-StringData -StringData 'a=b'

	$actualValue.Keys | Should -BeExactly "a"
    }

    It "Should return the data on the right side in the value" {
	$actualValue = ConvertFrom-StringData -StringData 'a=b'

	$actualValue.Values | Should -BeExactly "b"
    }

    It "Should return a keycollection for the keys" {
        $(ConvertFrom-StringData -StringData 'a=b').Keys.PSObject.TypeNames[0] | Should -BeExactly "System.Collections.Hashtable+KeyCollection"
    }

    It "Should return a valuecollection for the values" {
	$(ConvertFrom-StringData -StringData 'a=b').Values.PSObject.TypeNames[0] | Should -BeExactly "System.Collections.Hashtable+ValueCollection"
    }

    It "Should work for multiple lines" {
	{ ConvertFrom-StringData -StringData $sampleData } | Should -Not -Throw

    # keys are not order guaranteed
	$(ConvertFrom-StringData -StringData $sampleData).Keys   | Should -BeIn @("foo", "bar", "bazz")

	$(ConvertFrom-StringData -StringData $sampleData).Values | Should -BeIn @("0","1","2")
    }
}

Describe "Delimiter parameter tests" -Tags "CI" {
    BeforeAll  {
        $TestCases = @(
            @{ Delimiter = ':'; StringData = 'value:10'; ExpectedResult = @{ value = 10 } }
            @{ Delimiter = '-'; StringData = 'a-b' ; ExpectedResult = @{ a = 'b' } }
            @{ Delimiter = ','; StringData = 'c,d' ; ExpectedResult = @{ c = 'd' } }
        )
    }

    It "Default delimiter '=' works" {
        $actualValue = ConvertFrom-StringData -StringData 'a=b'

        $actualValue.Values | Should -BeExactly "b"
        $actualValue.Keys | Should -BeExactly "a"
    }

    It "Should not throw on given delimiter" {
        $sampleData = @"
a:b
"@
        { $sampleData | ConvertFrom-StringData -Delimiter ':' } | Should -Not -Throw
    }

    It 'is able to parse <StringData> with delimiter "<Delimiter> with <stringdata>"' -TestCases $TestCases {
        param($Delimiter, $StringData, $ExpectedResult)

        $Result = ConvertFrom-StringData -StringData $StringData -Delimiter $Delimiter

        $key = $ExpectedResult.Keys

        # validate the key in expected and result hashtables match
        $Result.Keys | Should -BeExactly $ExpectedResult.Keys

        # validate the values in expected and result hashtables match
        $Result[$key] | Should -BeExactly $ExpectedResult.Values
    }
}

Describe "Separator parameter tests" -Tags "CI" {
    BeforeAll  {
        $TestCases = @(
            @{ Separator = ' '; StringData = 'value0=10 value1=100 value3=1000'; ExpectedResult = @{ value0="10"; value1="100"; value3="1000"} }
            @{ Separator = ', '; StringData = 'a=b, c=d, e=f' ; ExpectedResult = @{  a="b"; c="d"; e="f"} }
            @{ Separator = ';'; StringData = 'cat = dog; car = truck' ; ExpectedResult = @{ cat = "dog"; car = "truck" } }
            @{ Separator = '🐍'; StringData = 'name = snake 🐍 sound = sss 🐍 legs = 0' ; ExpectedResult = @{ name = "snake" ; sound = "sss" ; legs = "0" } }
        )
    }

    It "Default Separator '\n' works" {
        $actualValue = ConvertFrom-StringData -StringData "
a=b
c=d
        "

        $actualValue.Values | Sort-Object | Should -BeExactly @("b"; "d")
        $actualValue.Keys | Sort-Object | Should -BeExactly @("a"; "c")
        $actualValue.a | Should -Eq "b"
        $actualValue.c | Should -Eq "d"

    }

    It "Should not throw on given Separator" {
        $sampleData = "a=b, c=d"
        { $sampleData | ConvertFrom-StringData -Separator ',' } | Should -Not -Throw
    }

    It 'is able to parse <StringData> with Separator "<Separator> with <stringdata>"' -TestCases $TestCases {
        param($Separator, $StringData, $ExpectedResult)

        $Result = ConvertFrom-StringData -StringData $StringData -Separator $Separator

        $keys = $ExpectedResult.Keys | Sort-Object
        $values = $ExpectedResult.Values | Sort-Object

        # validate the keys in expected and result hashtables match
        $Result.Keys | Sort-Object | Should -BeExactly $keys

        # validate the values in expected and result hashtables match
        $Result[$keys] | Sort-Object | Should -BeExactly $values
    }



}
