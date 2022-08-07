local csv = require('util.csv')
local event = lstg.eventDispatcher
lstg.text = {}
lstg.text.rootpath = "data\\text\\"
lstg.text.language = "English"
lstg.text.path = lstg.text.rootpath .. lstg.text.language .. '\\'
lstg.text.extension = ".tsv"
---the csvs that are loaded automatically
---(entries should be a table, where [1] is the name, and [2] is the parameters.)
---if [3] is a function, it will be used to load it (unimplemented at the time).
lstg.text.list = {}
--table.insert(lstg.text.list,{'title_screen', {header = {'Name', 'Nicki Minaj'}}})
---where the csvs are stored
lstg.text.data = {}
lstg.strings = lstg.text.data

function UpdateLanguage(newlang)
    lstg.text.language = newlang
    lstg.text.path = lstg.text.rootpath .. newlang .. '\\'
    LoadCSVList()
    event:dispatchEvent('updateLanguage', newlang)
end

function LoadCSVList()
    for k,v in pairs(lstg.text.list) do
        LoadCSVToTable(v[1], v[2])
    end
end

---name = the name of the file
---params = the parameters of the csv. normally you want to list down the headers you have inside it ( do { header = {"header1"}})
---also, params has more possible options, which is id_header. when you set it to a value, the tables will have another copy of every
---entry, but it will be stored according to the header with the same value as id_header.
---there's also ignore_id, which will Not store it on the array part, saving a lil bit of space
---@return table contents of the csv
function LoadCSV(name,params)
    local ret = {}
    local f = csv.open(lstg.text.path..name..lstg.text.extension,params)
    local i = 1
    for fields in f:lines() do
        if not params.ignore_id then
            ret[i] = {}
        end
        if params.id_header then
            ret[fields[params.id_header]] = {}
        end
        for k,v in pairs(fields) do
            if not params.ignore_id then
                ret[i][k] = v
            end
            if params.id_header then
                ret[fields[params.id_header]][k] = v
            end
        end
        i = i + 1
    end
    return ret
end
---same thing as LoadCSV, but automatically inserts it in lstg.text
function LoadCSVToTable(name, params, tablename)
    tablename = tablename or name
    lstg.text[tablename] = LoadCSV(name, params)
    return lstg.text[tablename]
end

function LoadCSVRaw(name, params)
    return csv.open(lstg.text.path..name..lstg.text.extension,params)
end