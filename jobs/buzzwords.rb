buzzwords = ['Jennifer', 'Angie', 'Tom', 'Neil', 'RJ', 'J.Witt', 'Rasnic', 'Seruya', 'Daniel']
buzzword_counts = Hash.new({ value: 0 })

SCHEDULER.every '2s' do
  random_buzzword = buzzwords.sample
  buzzword_counts[random_buzzword] = { label: random_buzzword, value: (buzzword_counts[random_buzzword][:value] + 1) % 30 }

  send_event('assigned', { items: buzzword_counts.values })
end
