var ent_filename;
ent_filename = get_save_filename("Entity file|*.ent","");
if(ent_filename == "") exit;

if (string_delete(ent_filename, 1, string_length(ent_filename)-4) != ".ent") ent_filename += ".ent";
ent_file = file_text_open_write(ent_filename);
file_text_write_string(ent_file, compressEntities());

file_text_close(ent_file);
