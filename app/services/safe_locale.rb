# Resolves a locale from untrusted input (an embed token, a domain setting),
# falling back through the candidates and finally to the default. Never lets an
# unknown locale through to I18n.
module SafeLocale
    module_function

    def resolve(*candidates)
        available = I18n.available_locales.map(&:to_s)
        candidates.each do |candidate|
            value = candidate.to_s
            return value.to_sym if available.include?(value)
        end
        I18n.default_locale
    end

    def supported?(candidate)
        I18n.available_locales.map(&:to_s).include?(candidate.to_s)
    end
end
