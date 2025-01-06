require 'task_config'

RSpec.describe GemSorter::TaskConfig do
  let(:default_config) { GemSorter::TaskConfig::DEFAULT_CONFIG }

  describe '#initialize' do
    context 'when no arguments are provided' do
      it 'sets default values' do
        config = described_class.new
        expect(config.backup).to eq(default_config['backup'])
        expect(config.update_comments).to eq(default_config['update_comments'])
        expect(config.update_versions).to eq(default_config['update_versions'])
        expect(config.ignore_gems).to eq(default_config['ignore_gems'])
        expect(config.gemfile_path).to eq(default_config['gemfile_path'])
      end
    end

    context 'when arguments are provided' do
      it 'overrides default values' do
        args = { backup: 'true', update_comments: 'false', ignore_gems: ['gem1', 'gem2'] }
        config = described_class.new(args)
        expect(config.backup).to be true
        expect(config.update_comments).to be false
        expect(config.ignore_gems).to eq(['gem1', 'gem2'])
      end
    end
  end

  describe '#load_config_from_file' do
    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(YAML).to receive(:load_file).and_return({
        'backup' => true,
        'update_comments' => false,
        'update_versions' => true,
        'ignore_gems' => ['gem1']
      })
    end

    it 'loads configuration from the YAML file' do
      config = described_class.new
      config.send(:load_config_from_file)
      expect(config.backup).to be true
      expect(config.update_comments).to be false
      expect(config.update_versions).to be true
      expect(config.ignore_gems).to eq(['gem1'])
    end
  end

  describe '#load_config_from_args' do
    it 'parses boolean values correctly' do
      args = { backup: 'false', update_comments: 'true', ignore_gems: ['gem1', 'gem2'] }
      config = described_class.new(args)
      expect(config.backup).to be false
      expect(config.update_comments).to be true
      expect(config.ignore_gems).to eq(['gem1', 'gem2'])
    end
  end

  describe '#gem_sorter_config_file_path' do
    it 'returns the correct config file path' do
      config = described_class.new
      expect(config.send(:gem_sorter_config_file_path)).to eq('gem_sorter.yml')
    end
  end
end 