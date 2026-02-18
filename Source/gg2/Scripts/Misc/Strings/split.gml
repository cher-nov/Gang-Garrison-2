// real split(string text, delimiter delimiter[, real limit])
// Splits string into items
// text - string comma-separated values
// delimiter - delimiter to split by
// limit (optional) - if specified, maximum times to split text
// When limited, the remaining text will be left as the last item.
// E.g. splitting "1,2,3,4,5" with delimiter "," and limit 2 yields this list:
// "1", "2", "3,4,5"
// return value - ds_list containing strings of values

var text, delimiter, limit;
text = argument0;
delimiter = argument1;
limit = argument2;

var list, count;
list = ds_list_create();
count = 0;

while true
{
    var cut;
    cut = string_pos(delimiter, text);
    if (cut <= 0) break;

    ds_list_add(list, string_copy(text, 1, cut - 1));
    text = string_delete(text, 1, cut - 1 + string_length(delimiter));

    count += 1;
    if (limit and count == limit)
        break;
}
ds_list_add(list, text);

return list;
