// Wordlists for Words tab in GridView
// Cluster data for Clusters tab in GridView
// 2021-02-01 : Muthu Nedumaran

1. Wordlists are plain text files with all the words saved in a single line, space delimited.

2. If you have a file with hundreds of thousand lines of one words, you can merge them into a single line by removing the \n:
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' file
    
3. The files are named as script_language.txt. All lower cased.
    Example: devanagari_hindi.txt, devanagari_marathi.txt, tamil_tamil.txt etc

4. Cluster data are in JSON format. The following arrays are mandatory: BaseNames, Nukta, SubConsonantNames, Vowel Signs, Other Signs, Numbers, UsesLakh, Hibizcus. If they are not relevant for the script, add a blank string element.

5. Cluster data is parsed by HBGridSidebarClusterViewModel.swift

