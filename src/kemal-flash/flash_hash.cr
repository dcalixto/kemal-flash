require "json"

module Kemal::Flash
  class FlashHash
    include JSON::Serializable

    property flashes : Hash(String, String)
    @discard : Set(String)

    def initialize
      @flashes = Hash(String, String).new
      @discard = Set(String).new
    end

    delegate each, empty?, keys, has_key?, delete, to_h, to: @flashes

    def self.from_json(string_or_io)
      parser = JSON::PullParser.new(string_or_io)
      flash_hash = self.new(parser)
      flash_hash.sweep
      return flash_hash
    end

    def to_json
      JSON.build do |json|
        to_json(json)
      end
    end

    def to_json(json : JSON::Builder)
      @flashes.reject!(@discard.to_a)
      @discard.clear

      json.object do
        json.field "flashes" { json.object {
          @flashes.each do |k, v|
            json.field k, v
          end
        } }
        json.field "discard" { json.array {
          @discard.each do |k|
            json.scalar(k)
          end
        } }
      end
    end

    include Session::StorableObject

    def update(h : Hash(String, String))
      @discard.subtract h.keys
      @flashes.merge!(h)
    end

    def []=(key : String, value : String)
      @flashes[key] = value
    end

    def [](key : String)
      @flashes[key]
    end

    def []?(k : String)
      @discard.add(k)
      @flashes[k]?
    end

    def sweep
      @flashes.reject! { |k, _| @discard.includes?(k) }
      @discard = Set(String).new(@flashes.keys)
    end

    def keep(key : String)
      @discard.delete(key) if @discard
    end

    def discard(key : String)
      @discard.add(key) if @discard
    end
  end
end
