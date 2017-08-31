describe FastlaneCore::CrashReporter do
  context 'crash reporting' do
    let(:exception) { double('Exception') }

    let(:stub_body) do
      {
        'key' => 'value'
      }
    end

    context 'post reports to Stackdriver' do
      before do
        silence_ui_output
        supress_crash_report_file_writing
        supress_opt_out_crash_reporting_file_writing
      end

      it 'posts a report to Stackdriver without specified type' do
        stub_stackdriver_request
        setup_crash_report_generator_expectation
        FastlaneCore::CrashReporter.report_crash(exception: exception)
      end

      it 'posts a report to Stackdriver with specified type' do
        stub_stackdriver_request(type: :crash)
        setup_crash_report_generator_expectation(type: :crash)
        FastlaneCore::CrashReporter.report_crash(type: :crash, exception: exception)
      end
    end

    context 'opted out of crash reporting' do
      before do
        silence_ui_output
        supress_opt_out_crash_reporting_file_writing
        supress_crash_report_file_writing
      end

      it 'does not post a report to Stackdriver if opted out' do
        ENV['FASTLANE_OPT_OUT_CRASH_REPORTING'] = '1'
        assert_not_requested(stub_stackdriver_request)
      end

      after do
        ENV['FASTLANE_OPT_OUT_CRASH_REPORTING'] = nil
      end
    end

    context 'write report to file' do
      before do
        silence_ui_output
        supress_stackdriver_reporting
        setup_crash_report_generator_expectation
        supress_opt_out_crash_reporting_file_writing
      end

      it 'writes a file with the json payload' do
        expect(File).to receive(:write).with(FastlaneCore::CrashReporter.crash_report_path, stub_body.to_json)

        FastlaneCore::CrashReporter.report_crash(exception: exception)
      end
    end
  end
end

def silence_ui_output
  allow(UI).to receive(:message)
end

def supress_opt_out_crash_reporting_file_writing
  allow(File).to receive(:write)
end

def supress_crash_report_file_writing
  allow(File).to receive(:write).with(FastlaneCore::CrashReporter.crash_report_path, stub_body.to_json)
end

def supress_stackdriver_reporting
  stub_stackdriver_request
end

def setup_crash_report_generator_expectation(type: :unknown)
  expect(FastlaneCore::CrashReportGenerator).to receive(:generate).with(
    type: type,
    exception: exception
  ).and_return(stub_body.to_json)
end

def stub_stackdriver_request(type: :unknown)
  stub_request(:post, %r{https:\/\/clouderrorreporting.googleapis.com\/v1beta1\/projects\/fastlane-166414\/events:report\?key=.*}).with do |request|
    request.body == stub_body.to_json
  end
end
