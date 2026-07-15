namespace :waiting_gifs do
  desc "Obfuscate app/assets/images/wait*.gif into wait*.bin, deleting the originals"
  task encode: :environment do
    images_dir = Rails.root.join("app/assets/images")
    sources = Dir.glob(images_dir.join("wait*.gif"))

    if sources.empty?
      puts "No wait*.gif files found in #{images_dir}"
      next
    end

    sources.each do |source_path|
      bytes = File.binread(source_path)
      dest_path = source_path.sub(/\.gif\z/, ".bin")
      File.binwrite(dest_path, WaitingGifsHelper.apply(bytes))
      File.delete(source_path)
      puts "encoded #{File.basename(source_path)} -> #{File.basename(dest_path)}"
    end
  end
end
