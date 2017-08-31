require 'scan'

describe Scan do
  describe Scan::Runner do
    describe "handle_results" do
      before(:each) do
        mock_slack_poster = Object.new
        allow(Scan::SlackPoster).to receive(:new).and_return(mock_slack_poster)
        allow(mock_slack_poster).to receive(:run)
        allow(Scan::TestCommandGenerator).to receive(:xcodebuild_log_path).and_return('./scan/spec/fixtures/boring.log')

        mock_test_result_parser = Object.new
        allow(Scan::TestResultParser).to receive(:new).and_return(mock_test_result_parser)
        allow(mock_test_result_parser).to receive(:parse_result).and_return({ tests: 100, failures: 0 })

        @scan = Scan::Runner.new
      end

      describe "with scan option :include_simulator_logs set to false" do
        it "does not copy any device logs to the output directory" do
          # Circle CI is setting the SCAN_INCLUDE_SIMULATOR_LOGS env var, so just leaving
          # the include_simulator_logs option out does not let it default to false
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            include_simulator_logs: false
          })

          expect(FastlaneCore::Simulator).not_to receive(:copy_logs)
          @scan.handle_results(0)
        end
      end

      describe "with scan option :include_simulator_logs set to true" do
        it "copies any device logs to the output directory" do
          # Circle CI is setting the SCAN_INCLUDE_SIMULATOR_LOGS env var, so just leaving
          # the include_simulator_logs option out does not let it default to false
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            include_simulator_logs: true
          })

          expect(FastlaneCore::Simulator).to receive(:copy_logs)
          @scan.handle_results(0)
        end
      end

      describe "Test Failure" do
        it "raises a FastlaneTestFailure instead of a crash or UserError" do
          expect do
            Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
              output_directory: '/tmp/scan_results',
              project: './scan/examples/standard/app.xcodeproj'
            })
            custom_parser = "custom_parser"
            expect(Scan::TestResultParser).to receive(:new).and_return(custom_parser)
            expect(custom_parser).to receive(:parse_result).and_return({ tests: 5, failures: 3 })

            @scan.handle_results(0)
          end.to raise_error FastlaneCore::Interface::FastlaneTestFailure, "Tests have failed"
        end
      end
    end
  end
end
