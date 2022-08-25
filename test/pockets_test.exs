defmodule PocketsTest do
  use ExUnit.Case, async: false

  alias Pockets.{DetsInfo, EtsInfo, Table}

  @ets_tid :test_ram
  @tmp_dets_path "test/tmp.dets"
  @tmp_dets_path2 "test/tmp2.dets"
  @persistent_dets_path "test/support/files/test.dets"

  setup do
    on_exit(fn ->
      File.rm(@tmp_dets_path)
      File.rm(@tmp_dets_path2)

      case :ets.info(@ets_tid) do
        :undefined ->
          nil

        _ ->
          :ets.delete(@ets_tid)
          # Pockets.Registry.unregister(@ets_tid)
      end

      Pockets.Registry.flush()
    end)
  end

  describe "close/1" do
    test ":ok on closing :dets table" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert :ok = Pockets.close(:test)
    end

    test ":ok on closing :ets table" do
      {:ok, _} = Pockets.open(:t1)
      assert :ok = Pockets.close(:t1)
    end

    test ":error attempting to close non-existant table" do
      assert {:error, _} = Pockets.close(:does_not_exist)
    end
  end

  describe "delete/2" do
    test "alias on success for :ets" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      Pockets.put(@ets_tid, :z, "Zulu")
      assert @ets_tid == Pockets.delete(@ets_tid, :z)
    end

    test "alias on success for :dets" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      Pockets.put(:t1, :z, "Zulu")
      assert :t1 == Pockets.delete(:t1, :z)
      assert nil == Pockets.get(:t1, :z)
    end

    test "alias when key does not exist" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert @ets_tid == Pockets.delete(@ets_tid, :z)
    end

    test ":error when table does not exist" do
      assert {:error, _} = Pockets.delete(:does_not_exist, :z)
    end
  end

  describe "destroy/1" do
    test ":ok on destroy :ets" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert :ok == Pockets.destroy(@ets_tid)
    end

    test ":ok on destroy :dets" do
      {:ok, _} = Pockets.new(:test, @tmp_dets_path)
      assert :ok == Pockets.destroy(:test)
    end
  end

  describe "empty?/1" do
    test "true on non-existent table" do
      assert true = Pockets.empty?(:does_not_exist)
    end

    test "true when table is empty" do
      assert {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert true == Pockets.empty?(@ets_tid)
    end

    test "false when table not empty" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert false == Pockets.empty?(:test)
    end
  end

  describe "exists?/1" do
    test "true when table exists" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert true == Pockets.exists?(@ets_tid)
    end

    test "false when table does not exist" do
      refute Pockets.exists?(:does_not_exist)
    end
  end

  describe "filter/2" do
    test "returns only entries for which fun returns a truthy value (ets)" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      Pockets.merge(@ets_tid, %{a: 12, b: 7, c: 22, d: 8})
      assert :ok = Pockets.filter(@ets_tid, fn {_, v} -> v > 10 end)
      assert %{a: 12, c: 22} == Pockets.to_map(@ets_tid)
    end

    test "returns only entries for which fun returns a truthy value (dets)" do
      Pockets.new(:test, @tmp_dets_path)
      Pockets.merge(:test, %{a: 12, b: 7, c: 22, d: 8})
      assert :ok = Pockets.filter(:test, fn {_, v} -> v > 10 end)
      assert %{a: 12, c: 22} == Pockets.to_map(:test)
    end

    test ":error when table does not exist" do
      assert {:error, _} = Pockets.filter(:does_not_exist, fn {_, v} -> v > 10 end)
    end
  end

  describe "get/3 type: :set" do
    test "returns value when key exists" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert "cat" == Pockets.get(:test, :c)
    end

    test "returns default when key does not exist" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert "my-default" == Pockets.get(:test, :missing, "my-default")
    end

    test "returns default when table does not exist" do
      assert "my-default" == Pockets.get(:does_not_exist, :missing, "my-default")
    end
  end

  describe "get/3 type: :bag" do
    test "returns values when key exists" do
      {:ok, _} = Pockets.new(:t1, :memory, type: :bag)
      Pockets.put(:t1, :x, "x")
      Pockets.put(:t1, :x, "x")
      Pockets.put(:t1, :x, "y")
      assert ["x", "y"] == Pockets.get(:t1, :x)
    end

    test "returns empty list when key does not exist" do
      {:ok, _} = Pockets.new(:t1, :memory, type: :bag)
      assert [] == Pockets.get(:t1, :missing, "my-default")
    end
  end

  describe "get/3 type: :duplicate_bag" do
    test "returns values when key exists" do
      {:ok, _} = Pockets.new(:t1, :memory, type: :duplicate_bag)
      Pockets.put(:t1, :x, "x")
      Pockets.put(:t1, :x, "x")
      Pockets.put(:t1, :x, "y")
      assert ["x", "x", "y"] == Pockets.get(:t1, :x)
    end

    test "returns empty list when key does not exist" do
      {:ok, _} = Pockets.new(:t1, :memory, type: :duplicate_bag)
      assert [] == Pockets.get(:t1, :missing, "my-default")
    end
  end

  describe "has_key?/2" do
    test "true when key exists" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert true == Pockets.has_key?(:test, :a)
    end

    test "false when key exists" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert false == Pockets.has_key?(:test, :foo)
    end
  end

  describe "incr/4" do
    test "adds to new key", %{test: test} do
      {:ok, _} = Pockets.new(:"#{test}")

      :"#{test}"
      |> Pockets.incr(:n)
      |> Pockets.incr(:n)
      |> Pockets.incr(:n)

      assert 3 == Pockets.get(:"#{test}", :n)
    end

    test "adds to new key using custom step", %{test: test} do
      {:ok, _} = Pockets.new(:"#{test}")

      :"#{test}"
      |> Pockets.incr(:n, 10)
      |> Pockets.incr(:n, 10)
      |> Pockets.incr(:n, 10)

      assert 30 == Pockets.get(:"#{test}", :n)
    end

    test "decrements", %{test: test} do
      {:ok, _} = Pockets.new(:"#{test}")

      :"#{test}"
      |> Pockets.incr(:n, -1)
      |> Pockets.incr(:n, -1)
      |> Pockets.incr(:n, -1)

      assert -3 == Pockets.get(:"#{test}", :n)
    end

    test "adds to new key using custom initial value", %{test: test} do
      {:ok, _} = Pockets.new(:"#{test}")

      :"#{test}"
      |> Pockets.incr(:n, 1, 10)
      |> Pockets.incr(:n, 1)
      |> Pockets.incr(:n, 1)

      assert 13 == Pockets.get(:"#{test}", :n)
    end

    test "no action when existing key is not numeric", %{test: test} do
      {:ok, _} = Pockets.new(:"#{test}")

      :"#{test}"
      |> Pockets.put(:n, "Not Numeric")
      |> Pockets.incr(:n)

      assert "Not Numeric" == Pockets.get(:"#{test}", :n)
    end

    test ":error when table does not exist", %{test: test} do
      assert {:error, _} =
               :"#{test}"
               |> Pockets.incr(:n)
    end
  end

  describe "info/1" do
    test "DetsInfo struct for existing :dets table" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert %DetsInfo{} = Pockets.info(:test)
    end

    test "EtsInfo struct for existing :ets table" do
      assert {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert %EtsInfo{} = Pockets.info(@ets_tid)
    end

    test ":error when table not registered" do
      assert {:error, _} = Pockets.info(:who_dis)
    end
  end

  describe "info/2" do
    test "reads info from :dets" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert 3 == Pockets.info(:test, :size)
    end

    test "reads info from :ets" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert true == Pockets.info(@ets_tid, :named_table)
    end
  end

  describe "keys/2" do
    test "gets list of keys" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert [:a, :b, :c] == Pockets.keys(:test)
    end
  end

  describe "keys_stream/2" do
    test "gets list of keys" do
      {:ok, _} = Pockets.open(:test, @persistent_dets_path)
      assert is_function(Pockets.keys_stream(:test))
    end
  end

  describe "merge/2" do
    test "merges two tables" do
      {:ok, _} = Pockets.open(:t1)
      {:ok, _} = Pockets.open(:t2)
      Pockets.merge(:t1, %{x: "xray", y: "yellow"})
      Pockets.merge(:t2, %{a: "apple", b: "boy", x: "men"})
      assert :t1 == Pockets.merge(:t1, :t2)
      assert %{a: "apple", b: "boy", x: "men", y: "yellow"} == Pockets.to_map(:t1)
    end

    test "merges map into table" do
      {:ok, _} = Pockets.open(:t1)
      assert :t1 == Pockets.merge(:t1, %{x: "xray", y: "yellow"})
      assert %{x: "xray", y: "yellow"} == Pockets.to_map(:t1)
    end

    test ":error when table does not exist" do
      {:ok, _} = Pockets.open(:t1)
      Pockets.merge(:t1, %{x: "xray", y: "yellow"})
      assert {:error, _} = Pockets.merge(:t1, :t2)
    end
  end

  describe "new/3" do
    test ":ok for :memory" do
      assert {:ok, _} = Pockets.new(@ets_tid, :memory)
    end

    test ":ok for disk" do
      assert {:ok, _} = Pockets.new(:test_disk, @tmp_dets_path)
    end

    @tag capture_log: true
    test ":ok when table already exists" do
      assert {:ok, _} = Pockets.new(@ets_tid, :memory)
      assert {:ok, _} = Pockets.new(@ets_tid, :memory)
    end
  end

  describe "open/3" do
    test ":ok for :memory" do
      assert {:ok, _} = Pockets.open(@ets_tid, :memory)
    end

    @tag capture_log: true
    test ":ok with duplicate :memory opens" do
      {:ok, _} = Pockets.open(@ets_tid, :memory)
      assert {:ok, _} = Pockets.open(@ets_tid, :memory)
    end

    test ":ok open existing from disk" do
      {:ok, _} = Pockets.open(:test_disk_persist, @persistent_dets_path)
      assert %{a: "apple", b: "boy", c: "cat"} == Pockets.to_map(:test_disk_persist)
    end

    test ":error attempting to open non-existent file" do
      assert {:error, _} = Pockets.open(:test_disk_persist, @tmp_dets_path)
    end

    test ":ok attempting to open non-existent file with create?: true" do
      assert {:ok, _} = Pockets.open(:test_disk_persist, @tmp_dets_path, create?: true)
    end
  end

  describe "put/2" do
    test "alias returned after successful put" do
      {:ok, _} = Pockets.open(@ets_tid, :memory)
      assert @ets_tid == Pockets.put(@ets_tid, :foo, :bar)
    end

    test "returns :error tuple when table does not exist" do
      assert {:error, _} = Pockets.put(:does_not_exist, :foo, :bar)
    end
  end

  describe "reject/2" do
    test "removes entries for which fun returns a truthy value (ets)" do
      {:ok, _} = Pockets.new(@ets_tid, :memory)
      Pockets.merge(@ets_tid, %{a: 12, b: 7, c: 22, d: 8})
      assert :ok = Pockets.reject(@ets_tid, fn {_, v} -> v > 10 end)
      assert %{b: 7, d: 8} == Pockets.to_map(@ets_tid)
    end

    test "removes entries for which fun returns a truthy value (dets)" do
      Pockets.new(:test, @tmp_dets_path)
      Pockets.merge(:test, %{a: 12, b: 7, c: 22, d: 8})
      assert :ok = Pockets.reject(:test, fn {_, v} -> v > 10 end)
      assert %{b: 7, d: 8} == Pockets.to_map(:test)
    end

    test ":error when table does not exist" do
      assert {:error, _} = Pockets.reject(:does_not_exist, fn {_, v} -> v > 10 end)
    end
  end

  describe "save_as/3" do
    test ":ok saving :ets file to disk" do
      {:ok, _} = Pockets.open(@ets_tid, :memory)
      Pockets.merge(@ets_tid, %{zen: "art", motorcycle: "maintenance"})
      assert :ok == Pockets.save_as(@ets_tid, @tmp_dets_path)
      assert {:ok, _tid2} = Pockets.open(:t2, @tmp_dets_path)
      assert "art" == Pockets.get(:t2, :zen)
    end

    test ":ok saving :dets file to new location" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert :ok == Pockets.save_as(:t1, @tmp_dets_path2)
      assert {:ok, _} = Pockets.open(:t2, @tmp_dets_path2)
      assert "art" == Pockets.get(:t2, :zen)
    end

    test ":ok saving :dets file to its current location" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert :ok == Pockets.save_as(:t1, @tmp_dets_path)
    end

    test ":error on table not found" do
      assert {:error, _} = Pockets.save_as(:does_not_exist, @tmp_dets_path)
    end

    #    test ":error when target file is in use by another table" do
    test ":error when target exists but overwrite?: false" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      File.touch(@tmp_dets_path2)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert {:error, _} = Pockets.save_as(:t1, @tmp_dets_path2)
    end

    test ":ok when target exists but overwrite?: true" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      File.touch(@tmp_dets_path2)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert :ok = Pockets.save_as(:t1, @tmp_dets_path2, overwrite?: true)
    end

    test ":error when target file is already in use by another table" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      {:ok, _} = Pockets.new(:t2, @tmp_dets_path2)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert {:error, _} = Pockets.save_as(:t1, @tmp_dets_path2, overwrite?: true)
    end
  end

  describe "show_tables/1" do
    test "empty list when no tables registered" do
      assert [] == Pockets.show_tables()
    end

    test "Table struct when tables registered" do
      {:ok, _} = Pockets.new(:t1)
      assert [%Table{alias: :t1}] = Pockets.show_tables()
    end
  end

  describe "size/1" do
    test "0 on empty" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      assert 0 == Pockets.size(:t1)
    end

    test "proper size" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert 2 == Pockets.size(:t1)
    end
  end

  describe "to_list/1" do
    test "returns list" do
      {:ok, _} = Pockets.new(:t1, @tmp_dets_path)
      Pockets.merge(:t1, %{zen: "life"})
      assert [zen: "life"] == Pockets.to_list(:t1)
    end
  end

  describe "to_map/1" do
    test "returns map" do
      {:ok, _} = Pockets.new(:t1)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert %{zen: "art", motorcycle: "maintenance"} == Pockets.to_map(:t1)
    end

    test "returns empty map when table does not exist" do
      assert %{} == Pockets.to_map(:does_not_exist)
    end
  end

  describe "to_stream/1" do
    test "returns function" do
      {:ok, _} = Pockets.new(:t1)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert is_function(Pockets.to_stream(:t1))
    end
  end

  describe "truncate/1" do
    test "alias on successful removal of all entries" do
      {:ok, _} = Pockets.new(:t1, :memory, compressed: true)
      Pockets.merge(:t1, %{zen: "art", motorcycle: "maintenance"})
      assert :t1 == Pockets.truncate(:t1)
      assert true == Pockets.info(:t1, :compressed)
    end
  end
end
