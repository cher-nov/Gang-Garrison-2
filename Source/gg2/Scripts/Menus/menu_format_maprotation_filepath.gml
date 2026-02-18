var LIMIT;
LIMIT = 30;

if (argument0 == "")
    return "None (map order from gg2.ini)";
else if (string_length(argument0) <= LIMIT)
    return argument0;
else  // ellipsis to show in a length-limited interface field
    return "..." + string_delete(argument0, 1, string_length(argument0)-(LIMIT-3));
