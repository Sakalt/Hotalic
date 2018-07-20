require "cgi"
require "json"

words = []

doc = File.read(File.expand_path("../../resources/Viku_-_An_Art_Language.htm", __FILE__))
doc.force_encoding(Encoding::ISO_8859_1)
doc.encode!("utf-8")

lines = doc.lines

def Word(form, *args)
  word = {
    entry: { id: -1, form: form },
    translations: [],
    tags: [],
    contents: [],
    variations: [],
    relations: []
  }
  args.each {|arg|
    key, value = arg
    word[key] << value
  }
  return word
end

def Translation(title, *forms)
  return :translations, { title: title, forms: forms }
end

def Tag(tag)
  return :tags, tag
end

def Content(title, text)
  return :contents, { title: title, text: text }
end

def pluck_tr(line)
  line.sub!(/^(?:<tbody>)?<tr><td>/, "")
  line.sub!(/(?:<\/td><\/tr>)?\n$/, "")
  line.gsub!(/<\/?b>/, "*")
  return CGI.unescapeHTML(line).split("</td><td>")
end


# BEGIN

### Sentence Structure

words << Word("an", Translation("structure", "ART"), Content("description", "common article"))
words << Word("in", Translation("structure", "ART"), Content("description", "name article"))
words << Word("un", Translation("structure", "ART"), Content("description", "functor article"))

words << Word("iv", Translation("structure", "BEGIN"))
words << Word("uv", Translation("structure", "END"))


lines[116..127].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Plurals

words << Word("pan", Translation("structure", "PL"))
# words << Word("satus", Translation("structure", "SG"))


### Varying the Order of Arguments

words << Word("kap", Translation("structure", "TAG1"))
words << Word("lap", Translation("structure", "TAG2"))
words << Word("nap", Translation("structure", "TAG3"))
words << Word("pap", Translation("structure", "TAG4"))
words << Word("sap", Translation("structure", "TAG5"))


### Switching Place Values

words << Word("lip", Translation("structure", "ORD2"))
words << Word("nip", Translation("structure", "ORD3"))
words << Word("pip", Translation("structure", "ORD4"))
words << Word("sip", Translation("structure", "ORD5"))


### Questions

words << Word("kal", Translation("structure", "yes/no"))
words << Word("kul", Translation("structure", "who/what/where/why/when"))
words << Word("kil", Translation("structure", "question predicate"))


### Positive-Negative Scale

words << Word("vak", Translation("structure", "strong positive, yes, indeed, certainly"))
words << Word("vik", Translation("structure", "somewhat positive"))
words << Word("vuk", Translation("structure", "neutral"))
words << Word("nik", Translation("structure", "negative"))
words << Word("nuk", Translation("structure", "opposite"))


### Imperatives

words << Word("vit", Translation("structure", "ABRUPT"))
words << Word("vis", Translation("structure", "POLITE"))


### Temporal Tense

lines[271..279].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Spatial Tense

lines[306..314].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Aspect

lines[344..378].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]), Content("example", r[2]))
}


### Relative Clauses

lines[394..397].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Events

lines[419..420].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Connectives

lines[450..454].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Compounding and Modification

words << Word("las", Translation("structure", "of"))
words << Word("lus", Translation("structure", "END"))


### Reference

words << Word("tap", Translation("structure", "it"))


### Attitudinals or Emotional Indicators

lines[502..517].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


### Discursives

mojibake = "\u00C3\u00A2\u00E2\u0082\u00AC\u00E2\u0080\u009C"
mistake = /^<\/tr>|<tr>(?=\n$)/

lines[527..536].each {|line|
  line.gsub!(mistake, "")
  line.gsub!(mojibake, "-")
  r = pluck_tr(line)
  rr = [r[0].split(" - "), r[1].split(" - ")].transpose
  rr.each {|r|
    words << Word(r[0], Translation("structure", r[1]))
  }
}


### Numbers

lines[546..555].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}

lines[559..568].each {|line|
  r = pluck_tr(line)
  words << Word(r[0], Translation("structure", r[1]))
}


## Vocabulary

meaningful_vocabulary = lines[621..1834]
re = /^<b>\t(\w+)\t<\/b>\t(?:&nbsp;){3}\t(.+?)\t(?:&nbsp;){3}\t(.+?)<br>\n$/

meaningful_vocabulary.each {|line|
  throw "no match: #{line}" unless line =~ re
  words << Word($1, Translation("predicate", $2), Content("definition", $3))
}


meaningless_vocabulary = lines[1835..1870]
re = /^<b>\t(\w+)\t<\/b>\t(?:&nbsp;){3}\t(?:&nbsp;){3}<br>\n$/

meaningless_vocabulary.each {|line|
  throw "no match: #{line}" unless line =~ re
  words << Word($1)
}


## Etymology

lines[1879..1893].each {|line|
  r = pluck_tr(line)
  ww = r[0].split(", ")
  ww.each {|w|
    found = words.find {|word| word[:entry][:form] == w }
    key, value = Content("etymology", r[2])
    found[key] << value
  }
}

# END

words.each_with_index {|word, id|
  word[:entry][:id] = id
}

dictionary = {
  words: words
}


File.write(
  File.expand_path("../viku.json", __FILE__),
  JSON.pretty_generate(dictionary)
)
File.write(
  File.expand_path("../viku.min.json", __FILE__),
  JSON.generate(dictionary)
)
