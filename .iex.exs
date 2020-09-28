# Some convenience functions here e.g.
# create_ets.(:something)
# create_dets.(:"/tmp/foo2")
create_ets = fn name -> :ets.new(name, [:set, :public, :named_table]) end
create_dets = fn file_as_atom -> :dets.open_file(file_as_atom, [type: :set]) end
