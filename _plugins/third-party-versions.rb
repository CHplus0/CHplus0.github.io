# Expands the "{{version}}" placeholder in third_party_libraries URLs.
#
# _config.yml stores CDN URLs like "https://cdn.jsdelivr.net/npm/mathjax@{{version}}/..."
# together with a `version` field. Without this expansion the placeholder is emitted
# literally, every CDN request 404s, and MathJax / jQuery / medium-zoom never load.
module ThirdPartyVersions
  def self.expand(value, version)
    case value
    when String then value.gsub("{{version}}", version)
    when Hash then value.transform_values { |v| expand(v, version) }
    else value
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  libs = site.config["third_party_libraries"]
  next unless libs.is_a?(Hash)

  libs.each_value do |lib|
    next unless lib.is_a?(Hash) && lib["url"] && lib["version"]

    lib["url"] = ThirdPartyVersions.expand(lib["url"], lib["version"].to_s)
  end
end
