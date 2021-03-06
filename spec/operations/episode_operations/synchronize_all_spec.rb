require "rails_helper"

RSpec.describe EpisodeOperations::SynchronizeAll, type: :operation do
  let(:episodes) do
    [
      Fabricate.build(:episode, published_at: Time.parse("01-01-2016 01:10:10")),
      Fabricate.build(:episode, published_at: Time.parse("01-01-2016 02:10:10"))
    ]
  end
  let(:channel) { Fabricate.build(:channel, episodes: episodes) }

  context "when the feed has no items at all" do
    let(:items) do
      []
    end

    it "does not trigger any episode synchronization" do
      expect_any_instance_of(EpisodeOperations::SynchronizeAll).to_not receive(:run)

      run(EpisodeOperations::SynchronizeAll, channel: channel, feed_items: items)
    end
  end

  context "when the feed has items" do
    let(:items) do
      [
        double(:item, title: "foo-1", summary: "shorter-1", description: "001", url: "bar-1.mp3", publish_date: Time.parse("01-01-2017 10:10:10")),
        double(:item, title: "foo-2", summary: "shorter-2", description: "002", url: "bar-2.mp3", publish_date: Time.parse("01-01-2017 11:10:10")),
      ]
    end

    before do
      allow_any_instance_of(ChannelOperations::Synchronize).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                  title: items[0].title,
                                                                                  summary: items[0].summary,
                                                                                  description: items[0].description,
                                                                                  url: items[0].url,
                                                                                  published_at: items[0].publish_date,
                                                                                  channel: channel).and_return(true)
      allow_any_instance_of(ChannelOperations::Synchronize).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                  title: items[1].title,
                                                                                  summary: items[1].summary,
                                                                                  description: items[1].description,
                                                                                  url: items[1].url,
                                                                                  published_at: items[1].publish_date,
                                                                                  channel: channel).and_return(true)
    end

    context "and there is no new item published" do
      let(:episodes) do
        [
          Fabricate.build(:episode, published_at: Time.parse("01-02-2017 10:10:10")),
          Fabricate.build(:episode, published_at: Time.parse("01-02-2017 11:10:10"))
        ]
      end

      it "does not trigger any episode synchronization" do
        expect_any_instance_of(EpisodeOperations::SynchronizeAll).to_not receive(:run)

        run(EpisodeOperations::SynchronizeAll, channel: channel, feed_items: items)
      end
    end

    context "with only valid episodes" do
      it "triggers each episode's synchronization" do
        expect_any_instance_of(EpisodeOperations::SynchronizeAll).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                        title: items[0].title,
                                                                                        summary: items[0].summary,
                                                                                        description: items[0].description,
                                                                                        url: items[0].url,
                                                                                        published_at: items[0].publish_date,
                                                                                        channel: channel)

        expect_any_instance_of(EpisodeOperations::SynchronizeAll).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                        title: items[1].title,
                                                                                        summary: items[1].summary,
                                                                                        description: items[1].description,
                                                                                        url: items[1].url,
                                                                                        published_at: items[1].publish_date,
                                                                                        channel: channel)

        run(EpisodeOperations::SynchronizeAll, channel: channel, feed_items: items)
      end
    end

    context "with invalid episodes" do
      let(:items) do
        [
          double(:item, title: "foo-1", summary: "shorter-1", description: "001", url: "bar-1.mp3", publish_date: Time.parse("01-01-2017 10:10:10")),
          double(:item, title: "foo-2", summary: "shorter-2", description: "002", url: "bar-2.mp3", publish_date: Time.parse("01-01-2017 11:10:10")),
        ]
      end

      before do
        allow_any_instance_of(EpisodeOperations::SynchronizeAll).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                       title: items[0].title,
                                                                                       summary: items[0].summary,
                                                                                       description: items[0].description,
                                                                                       url: items[0].url,
                                                                                       published_at: items[0].publish_date,
                                                                                       channel: channel).and_raise("InvalidEpisode")
      end

      it "ignore errors" do
        expect {
          run(EpisodeOperations::SynchronizeAll, channel: channel, feed_items: items)
        }.to_not raise_error("InvalidEpisode")
      end

      it "triggers the next episodes in the sequence" do
        expect_any_instance_of(EpisodeOperations::SynchronizeAll).to receive(:run).with(EpisodeOperations::Synchronize,
                                                                                        title: items[1].title,
                                                                                        summary: items[1].summary,
                                                                                        description: items[1].description,
                                                                                        url: items[1].url,
                                                                                        published_at: items[1].publish_date,
                                                                                        channel: channel)

        run(EpisodeOperations::SynchronizeAll, channel: channel, feed_items: items)
      end
    end
  end
end
