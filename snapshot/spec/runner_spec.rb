describe Snapshot do
  describe Snapshot::Runner do
    let(:runner) { Snapshot::Runner.new }
    describe 'Parses embedded SnapshotHelper.swift' do
      it 'finds the current embedded version' do
        helper_version = runner.version_of_bundled_helper
        expect(helper_version).to match(/^SnapshotHelperVersion \[\d.\d\]$/)
      end
    end

    describe 'output_simulator_logs' do
      before(:each) do
        allow(FileUtils).to receive(:cp).with(anything, anything)
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'copies all device logs to the output directory' do
        Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.available_options, {
          output_directory: '/tmp/scan_results',
          output_simulator_logs: true,
          devices: ['iPhone 6s', 'iPad Air'],
          project: './snapshot/example/Example.xcodeproj',
          scheme: 'ExampleUITests'
        })
        expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/iPhone .*_iOS_.*system.log})
        expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/iPad Air_iOS_.*system.log})
        runner.output_simulator_logs
      end
    end
  end
end
