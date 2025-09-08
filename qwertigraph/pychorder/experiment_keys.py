end_keys_all = '\'".,?!;:-_{}()[]/\+=|()@#$%^&*<>'
print(f"End keys all {end_keys_all}")
end_keys_array = list(end_keys_all)
# end_keys_array = [c for c in end_keys_all]


special_end_keys = {'Key.space': 1, 'Key.tab': 1, 'Key.enter': 1}
end_keys = special_end_keys 
end_keys_all_str = '\'".,?!;:-_{}()[]/\+=|()@#$%^*<>' # Not: &
end_keys_all_array = list(end_keys_all_str)
end_keys_all = {}
for end_key in end_keys_all_array:
    end_keys_all[end_key] = 1
    end_keys[end_key] = 1



for end_key, value in end_keys.items():
    print(f"key {end_key}")
