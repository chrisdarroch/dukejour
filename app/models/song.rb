class Song < ActiveRecord::Base

  include TrackSongCommon

  public_resource_for :read, :index

  has_many :tracks
  has_many :libraries, :through => :tracks

  delegate(
    :play!,

    :to => :track
  )

  before_save :set_normalized_fields

  def set_normalized_fields
    self.normalized_name   =   name.normalize unless name.nil?
    self.normalized_album  =  album.normalize unless album.nil?
    self.normalized_artist = artist.normalize unless artist.nil?
  end

  def self.suggestable
    ambition_context.within(Library.select {|l| l.active }, :libraries)
  end

  def display_name
    "#{artist} [#{album}] - #{track_number} #{name}"
  end

  def best_track
    tracks.sort_by(&:quality).reverse.detect {|t|
      returning !t.source.nil? do |result|
        puts "Source for #{t.persistent_id} #{result ? 'present' : 'missing'}."
      end
    }
  end

  def self.for track_source
    track_search_artist = to_search_field(track_source.artist)
    track_search_name = to_search_field(track_source.name)
    track_duration = (track_source.duration || -1).round
    select {|song|
      song.search_artist == track_search_artist &&
      song.search_name == track_search_name &&

      song.duration >= track_duration - 3 &&
      song.duration <= track_duration + 3
    }.first || Song.create(
      :search_artist => track_search_artist,
      :search_name => track_search_name,
      :duration => track_duration
    )
  end

  def update_metadata
    unless tracks.length.zero? # empty? would do a count(*), then tracks would be a second query.
      adjust Hash[*metadata_cols.zip(tracks.map {|t|
        metadata_cols.map {|c| t.send c }
      }.transpose).map {|col,data|
        [col, data.compact.hash_by(:self, &:length).sort_by {|_,v| -v }.first.first]
      }.flatten]
    end
  end


  private

  def metadata_cols
    [:artist, :album, :name, :year, :duration]
  end

  def self.to_search_field field
    field.downcase.gsub(/\b(the|a|an|and)\b/, '').normalize.gsub(/\W/, '')
  end

end
