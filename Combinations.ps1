function addToList ($list, $element) {
    $null = $list.Add($element)
}

function addRangeToList ($list, $elements) {
    $null = $list.AddRange($elements)
}

function newArrayList(){
    return New-Object System.Collections.ArrayList
}

function combinations ($strings, $length) {

    $emptyList = newArrayList

    # Base case: empty list or length is 0
    if ($length -eq 0) {
        return ,$newList
    } 
    if ($strings.Count -eq 0) { 
        $newList = newArrayList
        addToList $newList $emptyList
        return ,$emptyList
    }

    # Recursive case:
    # Remove the first item
    $first = $strings[0]

    if ($strings.Count -eq 1) {
        $remaining = $emptyList
    }else {
        $remaining = $strings.GetRange(1, $strings.Count - 1)
    }

    # Generate combinations with the first item
    $withFirst = newArrayList
    foreach ($combo in (combinations $remaining ($length - 1))) {
        $newCombo = newArrayList
        addToList $newCombo $first
        addRangeToList $newCombo $combo
        addToList $withFirst $newCombo
    }

    # Generate combinations without the first item
    $withoutFirst = combinations $remaining $length

    # Return the combination of both results
    $combinedResult = newArrayList
    addRangeToList $combinedResult $withFirst
    addRangeToList $combinedResult $withoutFirst

    return ,$combinedResult
}

$strings = New-Object System.Collections.ArrayList
addRangeToList $strings @('apple', 'banana', 'cherry', 'mango')

$result = combinations $strings 2

foreach ($combo in $result) {
    $joined = $combo -join ","
    write-output $joined
}
