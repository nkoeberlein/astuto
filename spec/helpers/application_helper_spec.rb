require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  context 'custom_css_for_style_tag method' do
    it 'keeps ordinary CSS unchanged, including child selectors' do
      css = ".header > a { color: #f00; }"

      expect(helper.custom_css_for_style_tag(css)).to eq(css)
    end

    it 'never lets a closing style tag through, even when nested' do
      [
        '</style><script>alert(1)</script>',
        '</STYLE ><script>alert(1)</script>',
        '</sty</stylele><script>alert(1)</script>'
      ].each do |payload|
        result = helper.custom_css_for_style_tag(payload)

        expect(result).not_to include('<')
        expect(result.downcase).not_to include('</style')
      end
    end

    it 'writes "<" as the CSS escape \3c' do
      expect(helper.custom_css_for_style_tag('a::after { content: "<"; }'))
        .to eq('a::after { content: "\3c "; }')
    end

    it 'returns an empty html_safe string for nil' do
      result = helper.custom_css_for_style_tag(nil)

      expect(result).to eq('')
      expect(result).to be_html_safe
    end
  end
end
