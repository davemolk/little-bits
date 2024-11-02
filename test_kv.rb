require 'test/unit'
require 'fileutils'
require 'tmpdir'
require_relative './kv'

class TestFileDB < Test::Unit::TestCase
  def setup
    @tmp_root = Dir.mktmpdir
    @test_dir = File.join(@tmp_root, "test_kv_store")
    FileUtils.mkdir_p(@test_dir)
    @db = FileDB.new(@test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_set_and_get
    @db.set("test_key", "value1", "value2")
    assert_equal(["value1", "value2"], @db.get("test_key"))
  end

  def test_set_overwrites_previous
    @db.set("test_key", "value1", "value2")
    @db.set("test_key", "value3", "value4")
    assert_equal(["value3", "value4"], @db.get("test_key"))
  end

  def test_set_empty
    @db.set("", "value1", "value2")
    assert_empty(@db.keys)
    @db.set(nil, "value1", "value2")
    assert_empty(@db.keys)
    @db.set("key", "")
    assert_equal([""], @db.get("key"))
    @db.set("key", nil)
    assert_equal([nil], @db.get("key"))
  end

  def test_add
    @db.set("test_key", "value1")
    @db.add("test_key", "value2", "value3")
    assert_equal(["value1", "value2", "value3"], @db.get("test_key"))
  end

  def test_add_duplicates
    @db.set("test_key", "value1", "value2")
    @db.add("test_key", "value2", "value3")
    assert_equal(["value1", "value2", "value3"], @db.get("test_key"))
  end

  def test_add_empty_key
    @db.set("test_key", "value1")
    # test add nil
    @db.add("", "value2", "value3")
    assert_equal(["value1"], @db.get("test_key"))
    @db.add(nil, "value2", "value3")
    assert_equal(["value1"], @db.get("test_key"))
  end

  def test_delete_specific_values
    @db.set("test_key", "value1", "value2", "value3")
    @db.delete("test_key", "value2")
    assert_equal(["value1", "value3"], @db.get("test_key"))
  end

  def test_delete_key
    @db.set("test_key", "value1", "value2", "value3")
    @db.delete("test_key")
    assert_nil(@db.get("test_key"))
  end

  def test_keys
    @db.set("test_key1", "value1")
    @db.set("test_key2", "value2")
    assert_equal(["test_key1", "test_key2"], @db.keys)
  end

  def test_replace_key
    @db.set("old_key", "value1", "value2")
    @db.replace("old_key", "new_key")
    assert_nil(@db.get("old_key"))
    assert_equal(["value1", "value2"], @db.get("new_key"))
  end

  def test_replace_value
    @db.set("test_key", "old_value")
    @db.replace("test_key", "old_value", "new_value")
    assert_equal(["new_value"], @db.get("test_key"))
  end

  def test_search_all
    @db.set("test_key", "test_value")
    @db.set("another_key", "another_value")
    keys, values = @db.search_all("test")
    assert_equal(["test_key"], keys)
    assert_equal([["test_key", "test_value"]], values)
  end

  def test_search_all_multiple_matches
    @db.set("test_key", "test_value")
    @db.set("another_key", "another_value")
    keys, values = @db.search_all("value")
    assert_empty(keys)
    assert_equal([["test_key", "test_value"], ["another_key", "another_value"]], values)
  end

  def test_persistence
    @db.set("persist_key", "persist_value")
    new_db = FileDB.new(@test_dir)
    assert_equal(["persist_value"], new_db.get("persist_key"))
  end
end