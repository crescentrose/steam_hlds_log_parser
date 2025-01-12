require "helper_spec"

module SteamHldsLogParser

  describe "SteamHldsLogParser" do

    before :all do
      @client         = Client.new(RSpecDisplayer)
      @handler        = Handler.new("", @client.displayer, @client.options)
      @custom_handler = Handler.new("", RSpecDisplayer, { :host => "0.0.0.0", :port => 27115, :display_changelevel => true })
    end

    describe "Handler" do

      context "when parameters are missing" do
        it "raises an exception" do
          expect { Handler.new }.to raise_error(ArgumentError)
        end
      end

      context "when parameters are given" do
        subject { @handler }
  
        context "when 'host' and 'port' are given"
        it { should be_an_instance_of Handler }
        it "has a 'host' option" do
          expect(@handler.options[:host]).not_to be_nil      
          expect(@handler.options[:host]).to eq("0.0.0.0")
        end
        it "has a 'port' option" do
          expect(@handler.options[:port]).not_to be_nil      
          expect(@handler.options[:port]).to be(27115)
        end

        describe "#post_init" do
          it "displays a console message when hlds connects" do
            expect(capture_stdout { @handler.post_init }).to eq("## 0.0.0.0:27115 => HLDS connected and sending data\n")
          end
        end

        describe "#unbind" do
          it "displays a console message when hlds disconnects" do
            expect(capture_stdout { @handler.unbind }).to eq("## 0.0.0.0:27115 => HLDS disconnected? No data is received.\n")
          end
        end

        describe "#receive_data" do

          context "when data is not supported" do
            it "returns anything" do
              data = '# L 05/10/2000 - 12:34:56: I am a fake line of log'
              expect(@handler.receive_data(data)).to be_nil
            end
          end

          context "when data is 'end_map'" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: Team "CT" scored "17" with "0" players"'
              expected = {:type=>"end_map", :params=>{:winner=>"CT", :score=>"17"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'end_round'" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: Team "CT" triggered "CTs_Win" (CT "3") (T "0")'
              expected = {:type=>"end_round", :params=>{:score_ct=>"3", :score_t=>"0"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'killed' (STEAM_ID_LAN)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Killer | Player<66><STEAM_ID_LAN><TERRORIST>" killed "Killed | Player<60><STEAM_ID_LAN><CT>" with "ak47"'
              expected = {:type=>"kill", :params => {:killer_team=>"T", :killer=>"Killer | Player",  :killed_team=>"CT", :killed=>"Killed | Player", :weapon=>"ak47"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'killed' (STEAM_0:0:12345)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Killer | Player<66><STEAM_0:0:12345><TERRORIST>" killed "Killed | Player<60><STEAM_0:0:12345><CT>" with "ak47"'
              expected = {:type=>"kill", :params => {:killer_team=>"T", :killer=>"Killer | Player",  :killed_team=>"CT", :killed=>"Killed | Player", :weapon=>"ak47"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'suicide' (STEAM_ID_LAN)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Player<66><STEAM_ID_LAN><TERRORIST>" committed suicide with "worldspawn" (world)'
              expected = {:type=>"suicide", :params=>{:killed=>"Player"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'suicide' (STEAM_0:0:12345)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Player<66><STEAM_0:0:12345><TERRORIST>" committed suicide with "worldspawn" (world)'
              expected = {:type=>"suicide", :params=>{:killed=>"Player"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'event' (STEAM_ID_LAN)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Killer | Player<66><STEAM_ID_LAN><CT>" triggered "Defused_The_Bomb"'
              expected = {:type=>"event", :params=> {:person_team=>"CT", :person=>"Killer | Player", :event_item=>"Defused_The_Bomb", :event_i18n=>"defused the bomb"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'event' (STEAM_0:0:12345)" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Killer | Player<66><STEAM_0:0:12345><CT>" triggered "Defused_The_Bomb"'
              expected = {:type=>"event", :params=> {:person_team=>"CT", :person=>"Killer | Player", :event_item=>"Defused_The_Bomb", :event_i18n=>"defused the bomb"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'changelevel'" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: Loading map "de_dust2"'
              expected = {:type=>"loading_map", :params=>{:map=>"de_dust2"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'chat'" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Player<15><STEAM_0:0:12345><TERRORIST>" say "gg" (dead)'
              expected = {:type=>"chat", :params=>{:player=>"Player", :player_team=>"T", :chat=>"gg"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end
          
          context "when data is 'team_chat'" do
            it "returns a Hash" do
              data = '# L 05/10/2000 - 12:34:56: "Player<15><STEAM_0:0:12345><TERRORIST>" say_team "Rush B"'
              expected = {:type=>"team_chat", :params=>{:player=>"Player", :player_team=>"T", :chat=>"Rush B"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'connect'" do
            it "returns Hash when a user connects the server" do
              data = '# L 05/10/2000 - 12:34:56: "Player<73><STEAM_ID_LAN><>" connected, address "192.168.4.186:1339"'
              expected = {:type=>"connect", :params=>{:player=>"Player", :ip=>"192.168.4.186", :port=>"1339"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          context "when data is 'disconnect'" do
            it "returns Hash when a user disconnects" do
              data = '# L 05/10/2000 - 12:34:56: "Player<73><STEAM_ID_LAN><TERRORIST>" disconnected'
              expected = {:type=>"disconnect", :params=>{:player=>"Player", :player_team=>"T"}}
              expect(@handler.receive_data(data).class).to be(RSpecDisplayer)
              expect(@handler.receive_data(data).data).to eq(expected)
              expect(@handler.receive_data(data).data.class).to be(Hash)
            end
          end

          subject { @custom_handler }
          context "when 'displayer' is set" do
            it "returns a Hash provided by 'displayer'" do
              data = '# L 05/10/2000 - 12:34:56: Loading map "de_dust2"'
              expected = {:type=>"loading_map", :params=>{:map=>"de_dust2"}}
              expect(@custom_handler.displayer).to be(RSpecDisplayer)
              expect(@custom_handler.options[:display_changelevel]).to be true
              expect(@custom_handler.receive_data(data).data).to eq(expected)
            end
          end

        end

        describe "#get_full_team_name" do
          context "when short name is given"
          it "returns full name" do
            expect(@handler.get_full_team_name("T")).to eq("Terrorist")
            expect(@handler.get_full_team_name("CT")).to eq("Counter-Terrorist")
          end
        end

        describe "#get_short_team_name" do
          context "when full name is given"
          it "returns short name" do
            expect(@handler.get_short_team_name("TERRORIST")).to eq("T")
            expect(@handler.get_short_team_name("CT")).to eq("CT")
          end
        end

      end

    end

  end

end
