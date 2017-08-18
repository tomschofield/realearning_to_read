# -*- coding: utf-8 -*-
import codecs
import sys
import nltk
import string
import io
import os
import unicodedata
from sklearn.feature_extraction.text import TfidfVectorizer
from nltk.stem.porter import PorterStemmer
from nltk.corpus import stopwords
import chardet
from nltk import pos_tag, word_tokenize
from bs4 import BeautifulSoup
import enchant
import json
import codecs



validPOS = [
'NN',
'NNP',
'NNPS',
'NNS']

d = enchant.Dict("en_UK")


def stem_tokens(tokens, stemmer):
    stemmed = []
    for item in tokens:
        stemmed.append(stemmer.stem(item))
    return stemmed

def tokenize(text):
    tokens = nltk.word_tokenize(text)
    stems = stem_tokens(tokens, stemmer)
    return stems

def filter_text_by_POS(text, validPOS):
	a = nltk.word_tokenize(text)
	tagged = nltk.pos_tag(a)
	filtered_text = ""
	for item in tagged:
		#print item[1]
		isValid = False
		for tag in validPOS:
			if tag == item[1]:
				isValid = True
		if isValid:
			filtered_text+=item[0]
			filtered_text+=" "
	return filtered_text


def get_tfidf(text):
	#print filter_text_by_POS(text, validPOS)


	#we have to encode back to ascii to get the punctuation stripper to work
	sText = unicodedata.normalize('NFKD', text).encode('ascii','ignore')
	#now convert to lower case
	lowers = sText.lower()
	#now strip punctuation
	no_punctuation = sText.translate(None, string.punctuation)

	#now blow it up to a list
	exploded = no_punctuation.split(' ')

	#make a list excluding stop words
	filtered = [w for w in exploded if not w in stopwords.words('english')]
	no_stop_words = ""
	#reconstruct a paragraph without stop words
	for item in filtered:
		
		no_stop_words+=item
		no_stop_words+=" "

	#print no_stop_words

	token_dict[file] = no_stop_words 

	tfidf = TfidfVectorizer(tokenizer=tokenize, stop_words='english')

	tfs = tfidf.fit_transform(token_dict.values())
	feature_names = tfidf.get_feature_names()
	unsortedList = []
	for col in tfs.nonzero()[1]:
		#print feature_names[col],' ',feature_names[col].__len__(), ' - ', tfs[0, col]
		inVar  = feature_names[col]
		
		singleItem = (inVar.encode('utf-8'),tfs[0, col])
		unsortedList.append(singleItem)
	#print unsortedList
		sorted_list = sorted(unsortedList, key=lambda item: item[1], reverse=True)

	clean_list = []
	for line in sorted_list:
		#print line
		word = str(line[0])
		if word.__len__()>3 and d.check(word):
			clean_list.append(line)
	return clean_list


# path = './ripped_text/'
# for subdir, dirs, files in os.walk(path):
#     for file in files:
#     	token_dict = {}
#     	stemmer = PorterStemmer()
#     	print file
#     	if file!='.DS_Store':
# 			file_path = subdir + os.path.sep + file
# 			f = codecs.open(file_path, 'r', 'UTF-8')
# 			text = f.read()
# 			try:
# 				tfidf_result = get_tfidf(filter_text_by_POS(text, validPOS))
# 				log = open('./results/'+file, 'w+')
# 				log.write(json.dumps(tfidf_result))
# 				log.close()
# 			except:
# 				print 'dodgy file'
	
#     for file in files:
token_dict = {}
stemmer = PorterStemmer()		
#f = codecs.open( 'atest.txt'   )#'BXB-1-1-DRA-1-3_22-23-1.txt', 'r', 'UTF-8')
with io.open("/Users/tomschofield/Dropbox/readingreading/install_v1/scripts/atext.txt", "r", encoding="utf-8") as my_file:
     text = my_file.read() 
#text = f.read()
tfidf_result = get_tfidf(filter_text_by_POS(text, validPOS))
log = open('/Users/tomschofield/Dropbox/readingreading/install_v1/scripts/result1.json', 'w+')
log.write(json.dumps(tfidf_result))
log.close()

