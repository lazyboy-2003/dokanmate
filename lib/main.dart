import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:printing/printing.dart';

final ValueNotifier<String> appLanguage = ValueNotifier<String>('English');

const Map<String, Map<String, String>> _i18n = {
  'English': {
    'Home':'Home','Sales':'Sales','Purchase':'Purchase','Parties':'Parties','More':'More','Inventory':'Inventory','Payments':'Payments','Expenses':'Expenses','Reports & Export':'Reports & Export','Merchant Profile':'Merchant Profile','Language':'Language','Save':'Save','Cancel':'Cancel','Business Overview':'Business Overview','Total Sales':'Total Sales','Collection':'Collection','Profit':'Profit','Receivable':'Receivable','Payable':'Payable','Stock Value':'Stock Value','Business Expenses':'Business Expenses','Quick Actions':'Quick Actions','Customers':'Customers','Suppliers':'Suppliers','Add Product':'Add Product','Select Customer':'Select Customer','Select Supplier':'Select Supplier','Payment mode':'Payment mode','Grand Total':'Grand Total','Due':'Due','Subtotal':'Subtotal','Discount':'Discount','Taxable':'Taxable','GST':'GST','Paid amount':'Paid amount','New Sales Invoice':'New Sales Invoice','New Purchase Invoice':'New Purchase Invoice','Sales Invoice':'Sales Invoice','Purchase Invoice':'Purchase Invoice','Select Product':'Select Product','Add Customer':'Add Customer','Add Supplier':'Add Supplier','App Language':'App Language',
  },
  'हिन्दी': {
    'Home':'होम','Sales':'बिक्री','Purchase':'खरीद','Parties':'पार्टियाँ','More':'और','Inventory':'इन्वेंटरी','Payments':'भुगतान','Expenses':'खर्च','Reports & Export':'रिपोर्ट और एक्सपोर्ट','Merchant Profile':'मर्चेंट प्रोफाइल','Language':'भाषा','Save':'सेव','Cancel':'रद्द करें','Business Overview':'बिजनेस ओवरव्यू','Total Sales':'कुल बिक्री','Collection':'कलेक्शन','Profit':'लाभ','Receivable':'लेना है','Payable':'देना है','Stock Value':'स्टॉक वैल्यू','Business Expenses':'बिजनेस खर्च','Quick Actions':'क्विक एक्शन','Customers':'ग्राहक','Suppliers':'सप्लायर','Add Product':'उत्पाद जोड़ें','Select Customer':'ग्राहक चुनें','Select Supplier':'सप्लायर चुनें','Payment mode':'भुगतान का तरीका','Grand Total':'कुल राशि','Due':'बकाया','Subtotal':'उप-योग','Discount':'छूट','Taxable':'कर योग्य','GST':'जीएसटी','Paid amount':'भुगतान राशि','New Sales Invoice':'नई बिक्री इनवॉइस','New Purchase Invoice':'नई खरीद इनवॉइस','Sales Invoice':'बिक्री इनवॉइस','Purchase Invoice':'खरीद इनवॉइस','Select Product':'उत्पाद चुनें','Add Customer':'ग्राहक जोड़ें','Add Supplier':'सप्लायर जोड़ें','App Language':'ऐप भाषा',
  },
  'বাংলা': {
    'Home':'হোম','Sales':'বিক্রয়','Purchase':'ক্রয়','Parties':'পার্টি','More':'আরও','Inventory':'ইনভেন্টরি','Payments':'পেমেন্ট','Expenses':'খরচ','Reports & Export':'রিপোর্ট ও এক্সপোর্ট','Merchant Profile':'মার্চেন্ট প্রোফাইল','Language':'ভাষা','Save':'সেভ','Cancel':'বাতিল','Business Overview':'ব্যবসার সারাংশ','Total Sales':'মোট বিক্রয়','Collection':'আদায়','Profit':'লাভ','Receivable':'পাওনা','Payable':'দেনা','Stock Value':'স্টকের মূল্য','Business Expenses':'ব্যবসার খরচ','Quick Actions':'দ্রুত কাজ','Customers':'গ্রাহক','Suppliers':'সরবরাহকারী','Add Product':'পণ্য যোগ করুন','Select Customer':'গ্রাহক নির্বাচন করুন','Select Supplier':'সরবরাহকারী নির্বাচন করুন','Payment mode':'পেমেন্টের মাধ্যম','Grand Total':'সর্বমোট','Due':'বাকি','Subtotal':'সাবটোটাল','Discount':'ছাড়','Taxable':'করযোগ্য','GST':'GST','Paid amount':'পরিশোধিত টাকা','New Sales Invoice':'নতুন বিক্রয় ইনভয়েস','New Purchase Invoice':'নতুন ক্রয় ইনভয়েস','Sales Invoice':'বিক্রয় ইনভয়েস','Purchase Invoice':'ক্রয় ইনভয়েস','Select Product':'পণ্য নির্বাচন করুন','Add Customer':'গ্রাহক যোগ করুন','Add Supplier':'সরবরাহকারী যোগ করুন','App Language':'অ্যাপের ভাষা',
  },
  'मराठी': {
    'Home':'मुख्यपृष्ठ','Sales':'विक्री','Purchase':'खरेदी','Parties':'पक्ष','More':'अधिक','Inventory':'साठा','Payments':'देयके','Expenses':'खर्च','Reports & Export':'अहवाल व एक्सपोर्ट','Merchant Profile':'व्यापारी प्रोफाइल','Language':'भाषा','Save':'जतन करा','Cancel':'रद्द करा','Business Overview':'व्यवसायाचा आढावा','Total Sales':'एकूण विक्री','Collection':'वसुली','Profit':'नफा','Receivable':'येणे','Payable':'देणे','Stock Value':'साठ्याची किंमत','Business Expenses':'व्यवसाय खर्च','Quick Actions':'जलद कृती','Customers':'ग्राहक','Suppliers':'पुरवठादार','Add Product':'उत्पादन जोडा','Select Customer':'ग्राहक निवडा','Select Supplier':'पुरवठादार निवडा','Payment mode':'पेमेंट पद्धत','Grand Total':'एकूण रक्कम','Due':'बाकी','Subtotal':'उपएकूण','Discount':'सूट','Taxable':'करपात्र','GST':'जीएसटी','Paid amount':'भरलेली रक्कम','New Sales Invoice':'नवीन विक्री चलन','New Purchase Invoice':'नवीन खरेदी चलन','Sales Invoice':'विक्री चलन','Purchase Invoice':'खरेदी चलन','Select Product':'उत्पादन निवडा','Add Customer':'ग्राहक जोडा','Add Supplier':'पुरवठादार जोडा','App Language':'अॅप भाषा',
  },
  'తెలుగు': {
    'Home':'హోమ్','Sales':'అమ్మకాలు','Purchase':'కొనుగోలు','Parties':'పార్టీలు','More':'మరిన్ని','Inventory':'నిల్వ','Payments':'చెల్లింపులు','Expenses':'ఖర్చులు','Reports & Export':'నివేదికలు & ఎగుమతి','Merchant Profile':'వ్యాపారి ప్రొఫైల్','Language':'భాష','Save':'సేవ్','Cancel':'రద్దు','Business Overview':'వ్యాపార అవలోకనం','Total Sales':'మొత్తం అమ్మకాలు','Collection':'వసూళ్లు','Profit':'లాభం','Receivable':'రావాల్సింది','Payable':'చెల్లించాల్సింది','Stock Value':'స్టాక్ విలువ','Business Expenses':'వ్యాపార ఖర్చులు','Quick Actions':'త్వరిత చర్యలు','Customers':'కస్టమర్లు','Suppliers':'సరఫరాదారులు','Add Product':'ఉత్పత్తి జోడించండి','Select Customer':'కస్టమర్ ఎంచుకోండి','Select Supplier':'సరఫరాదారు ఎంచుకోండి','Payment mode':'చెల్లింపు విధానం','Grand Total':'మొత్తం','Due':'బకాయి','Subtotal':'ఉపమొత్తం','Discount':'తగ్గింపు','Taxable':'పన్ను విధించదగినది','GST':'జీఎస్టీ','Paid amount':'చెల్లించిన మొత్తం','New Sales Invoice':'కొత్త అమ్మకాల ఇన్వాయిస్','New Purchase Invoice':'కొత్త కొనుగోలు ఇన్వాయిస్','Sales Invoice':'అమ్మకాల ఇన్వాయిస్','Purchase Invoice':'కొనుగోలు ఇన్వాయిస్','Select Product':'ఉత్పత్తిని ఎంచుకోండి','Add Customer':'కస్టమర్‌ను జోడించండి','Add Supplier':'సరఫరాదారుని జోడించండి','App Language':'యాప్ భాష',
  },
  'தமிழ்': {
    'Home':'முகப்பு','Sales':'விற்பனை','Purchase':'கொள்முதல்','Parties':'தரப்புகள்','More':'மேலும்','Inventory':'சரக்கு','Payments':'கொடுப்பனவுகள்','Expenses':'செலவுகள்','Reports & Export':'அறிக்கைகள் & ஏற்றுமதி','Merchant Profile':'வணிகர் சுயவிவரம்','Language':'மொழி','Save':'சேமி','Cancel':'ரத்து','Business Overview':'வணிக சுருக்கம்','Total Sales':'மொத்த விற்பனை','Collection':'வசூல்','Profit':'லாபம்','Receivable':'பெற வேண்டியது','Payable':'செலுத்த வேண்டியது','Stock Value':'சரக்கு மதிப்பு','Business Expenses':'வணிக செலவுகள்','Quick Actions':'விரைவு செயல்கள்','Customers':'வாடிக்கையாளர்கள்','Suppliers':'சப்ளையர்கள்','Add Product':'பொருள் சேர்','Select Customer':'வாடிக்கையாளரைத் தேர்வு செய்','Select Supplier':'சப்ளையரைத் தேர்வு செய்','Payment mode':'கட்டண முறை','Grand Total':'மொத்தம்','Due':'நிலுவை','Subtotal':'கூட்டுத்தொகை','Discount':'தள்ளுபடி','Taxable':'வரி விதிக்கத்தக்கது','GST':'ஜிஎஸ்டி','Paid amount':'செலுத்திய தொகை','New Sales Invoice':'புதிய விற்பனை இன்வாய்ஸ்','New Purchase Invoice':'புதிய கொள்முதல் இன்வாய்ஸ்','Sales Invoice':'விற்பனை இன்வாய்ஸ்','Purchase Invoice':'கொள்முதல் இன்வாய்ஸ்','Select Product':'பொருளைத் தேர்வு செய்','Add Customer':'வாடிக்கையாளரைச் சேர்','Add Supplier':'சப்ளையரைச் சேர்','App Language':'ஆப் மொழி',
  },
  'ગુજરાતી': {
    'Home':'હોમ','Sales':'વેચાણ','Purchase':'ખરીદી','Parties':'પાર્ટીઓ','More':'વધુ','Inventory':'ઇન્વેન્ટરી','Payments':'ચુકવણીઓ','Expenses':'ખર્ચ','Reports & Export':'રિપોર્ટ અને એક્સપોર્ટ','Merchant Profile':'મર્ચન્ટ પ્રોફાઇલ','Language':'ભાષા','Save':'સાચવો','Cancel':'રદ કરો','Business Overview':'બિઝનેસ ઓવરવ્યૂ','Total Sales':'કુલ વેચાણ','Collection':'વસૂલાત','Profit':'નફો','Receivable':'લેવાનું','Payable':'ચૂકવવાનું','Stock Value':'સ્ટોક મૂલ્ય','Business Expenses':'વ્યવસાય ખર્ચ','Quick Actions':'ઝડપી કાર્યો','Customers':'ગ્રાહકો','Suppliers':'સપ્લાયર્સ','Add Product':'પ્રોડક્ટ ઉમેરો','Select Customer':'ગ્રાહક પસંદ કરો','Select Supplier':'સપ્લાયર પસંદ કરો','Payment mode':'ચુકવણી પદ્ધતિ','Grand Total':'કુલ રકમ','Due':'બાકી','Subtotal':'પેટા કુલ','Discount':'ડિસ્કાઉન્ટ','Taxable':'કરપાત્ર','GST':'GST','Paid amount':'ચૂકવેલ રકમ','New Sales Invoice':'નવી વેચાણ ઇન્વોઇસ','New Purchase Invoice':'નવી ખરીદી ઇન્વોઇસ','Sales Invoice':'વેચાણ ઇન્વોઇસ','Purchase Invoice':'ખરીદી ઇન્વોઇસ','Select Product':'પ્રોડક્ટ પસંદ કરો','Add Customer':'ગ્રાહક ઉમેરો','Add Supplier':'સપ્લાયર ઉમેરો','App Language':'ઍપ ભાષા',
  },
  'اردو': {
    'Home':'ہوم','Sales':'فروخت','Purchase':'خریداری','Parties':'پارٹیاں','More':'مزید','Inventory':'انوینٹری','Payments':'ادائیگیاں','Expenses':'اخراجات','Reports & Export':'رپورٹس اور ایکسپورٹ','Merchant Profile':'مرچنٹ پروفائل','Language':'زبان','Save':'محفوظ کریں','Cancel':'منسوخ','Business Overview':'کاروباری جائزہ','Total Sales':'کل فروخت','Collection':'وصولی','Profit':'منافع','Receivable':'وصول طلب','Payable':'قابل ادائیگی','Stock Value':'اسٹاک کی قدر','Business Expenses':'کاروباری اخراجات','Quick Actions':'فوری کارروائیاں','Customers':'گاہک','Suppliers':'سپلائرز','Add Product':'پروڈکٹ شامل کریں','Select Customer':'گاہک منتخب کریں','Select Supplier':'سپلائر منتخب کریں','Payment mode':'ادائیگی کا طریقہ','Grand Total':'کل رقم','Due':'بقایا','Subtotal':'ذیلی کل','Discount':'رعایت','Taxable':'قابل ٹیکس','GST':'جی ایس ٹی','Paid amount':'ادا شدہ رقم','New Sales Invoice':'نیا فروخت انوائس','New Purchase Invoice':'نیا خریداری انوائس','Sales Invoice':'فروخت انوائس','Purchase Invoice':'خریداری انوائس','Select Product':'پروڈکٹ منتخب کریں','Add Customer':'گاہک شامل کریں','Add Supplier':'سپلائر شامل کریں','App Language':'ایپ کی زبان',
  },
  'ಕನ್ನಡ': {
    'Home':'ಮುಖಪುಟ','Sales':'ಮಾರಾಟ','Purchase':'ಖರೀದಿ','Parties':'ಪಕ್ಷಗಳು','More':'ಇನ್ನಷ್ಟು','Inventory':'ದಾಸ್ತಾನು','Payments':'ಪಾವತಿಗಳು','Expenses':'ವೆಚ್ಚಗಳು','Reports & Export':'ವರದಿಗಳು ಮತ್ತು ಎಕ್ಸ್‌ಪೋರ್ಟ್','Merchant Profile':'ವ್ಯಾಪಾರಿ ಪ್ರೊಫೈಲ್','Language':'ಭಾಷೆ','Save':'ಉಳಿಸಿ','Cancel':'ರದ್ದು','Business Overview':'ವ್ಯವಹಾರ ಅವಲೋಕನ','Total Sales':'ಒಟ್ಟು ಮಾರಾಟ','Collection':'ವಸೂಲಿ','Profit':'ಲಾಭ','Receivable':'ಬರಬೇಕಾದದ್ದು','Payable':'ಕೊಡಬೇಕಾದದ್ದು','Stock Value':'ಸ್ಟಾಕ್ ಮೌಲ್ಯ','Business Expenses':'ವ್ಯವಹಾರ ವೆಚ್ಚಗಳು','Quick Actions':'ತ್ವರಿತ ಕಾರ್ಯಗಳು','Customers':'ಗ್ರಾಹಕರು','Suppliers':'ಪೂರೈಕೆದಾರರು','Add Product':'ಉತ್ಪನ್ನ ಸೇರಿಸಿ','Select Customer':'ಗ್ರಾಹಕರನ್ನು ಆಯ್ಕೆಮಾಡಿ','Select Supplier':'ಪೂರೈಕೆದಾರರನ್ನು ಆಯ್ಕೆಮಾಡಿ','Payment mode':'ಪಾವತಿ ವಿಧಾನ','Grand Total':'ಒಟ್ಟು ಮೊತ್ತ','Due':'ಬಾಕಿ','Subtotal':'ಉಪಮೊತ್ತ','Discount':'ರಿಯಾಯಿತಿ','Taxable':'ತೆರಿಗೆಗೆ ಒಳಪಡುವ','GST':'ಜಿಎಸ್‌ಟಿ','Paid amount':'ಪಾವತಿಸಿದ ಮೊತ್ತ','New Sales Invoice':'ಹೊಸ ಮಾರಾಟ ಇನ್ವಾಯ್ಸ್','New Purchase Invoice':'ಹೊಸ ಖರೀದಿ ಇನ್ವಾಯ್ಸ್','Sales Invoice':'ಮಾರಾಟ ಇನ್ವಾಯ್ಸ್','Purchase Invoice':'ಖರೀದಿ ಇನ್ವಾಯ್ಸ್','Select Product':'ಉತ್ಪನ್ನ ಆಯ್ಕೆಮಾಡಿ','Add Customer':'ಗ್ರಾಹಕರನ್ನು ಸೇರಿಸಿ','Add Supplier':'ಪೂರೈಕೆದಾರರನ್ನು ಸೇರಿಸಿ','App Language':'ಆಪ್ ಭಾಷೆ',
  },
  'ଓଡ଼ିଆ': {
    'Home':'ମୁଖ୍ୟ ପୃଷ୍ଠା','Sales':'ବିକ୍ରୟ','Purchase':'କ୍ରୟ','Parties':'ପକ୍ଷଗୁଡ଼ିକ','More':'ଅଧିକ','Inventory':'ମଜୁତ','Payments':'ପେମେଣ୍ଟ','Expenses':'ଖର୍ଚ୍ଚ','Reports & Export':'ରିପୋର୍ଟ ଓ ଏକ୍ସପୋର୍ଟ','Merchant Profile':'ବ୍ୟବସାୟୀ ପ୍ରୋଫାଇଲ୍','Language':'ଭାଷା','Save':'ସଞ୍ଚୟ','Cancel':'ବାତିଲ','Business Overview':'ବ୍ୟବସାୟ ସାରାଂଶ','Total Sales':'ମୋଟ ବିକ୍ରୟ','Collection':'ଆଦାୟ','Profit':'ଲାଭ','Receivable':'ପାଇବାକୁ ଅଛି','Payable':'ଦେବାକୁ ଅଛି','Stock Value':'ଷ୍ଟକ୍ ମୂଲ୍ୟ','Business Expenses':'ବ୍ୟବସାୟ ଖର୍ଚ୍ଚ','Quick Actions':'ଦ୍ରୁତ କାର୍ଯ୍ୟ','Customers':'ଗ୍ରାହକ','Suppliers':'ଯୋଗାଣକାରୀ','Add Product':'ଉତ୍ପାଦ ଯୋଡ଼ନ୍ତୁ','Select Customer':'ଗ୍ରାହକ ବାଛନ୍ତୁ','Select Supplier':'ଯୋଗାଣକାରୀ ବାଛନ୍ତୁ','Payment mode':'ପେମେଣ୍ଟ ପ୍ରକାର','Grand Total':'ମୋଟ ରାଶି','Due':'ବାକି','Subtotal':'ଉପମୋଟ','Discount':'ଛାଡ଼','Taxable':'କରଯୋଗ୍ୟ','GST':'ଜିଏସଟି','Paid amount':'ଦିଆଯାଇଥିବା ରାଶି','New Sales Invoice':'ନୂଆ ବିକ୍ରୟ ଇନଭଏସ୍','New Purchase Invoice':'ନୂଆ କ୍ରୟ ଇନଭଏସ୍','Sales Invoice':'ବିକ୍ରୟ ଇନଭଏସ୍','Purchase Invoice':'କ୍ରୟ ଇନଭଏସ୍','Select Product':'ଉତ୍ପାଦ ବାଛନ୍ତୁ','Add Customer':'ଗ୍ରାହକ ଯୋଡ଼ନ୍ତୁ','Add Supplier':'ଯୋଗାଣକାରୀ ଯୋଡ଼ନ୍ତୁ','App Language':'ଆପ୍ ଭାଷା',
  },
  'മലയാളം': {
    'Home':'ഹോം','Sales':'വിൽപ്പന','Purchase':'വാങ്ങൽ','Parties':'പാർട്ടികൾ','More':'കൂടുതൽ','Inventory':'ഇൻവെന്ററി','Payments':'പേയ്മെന്റുകൾ','Expenses':'ചെലവുകൾ','Reports & Export':'റിപ്പോർട്ടുകളും എക്സ്പോർട്ടും','Merchant Profile':'മർച്ചന്റ് പ്രൊഫൈൽ','Language':'ഭാഷ','Save':'സേവ്','Cancel':'റദ്ദാക്കുക','Business Overview':'ബിസിനസ് അവലോകനം','Total Sales':'ആകെ വിൽപ്പന','Collection':'പിരിവ്','Profit':'ലാഭം','Receivable':'ലഭിക്കാനുള്ളത്','Payable':'നൽകാനുള്ളത്','Stock Value':'സ്റ്റോക്ക് മൂല്യം','Business Expenses':'ബിസിനസ് ചെലവുകൾ','Quick Actions':'ദ്രുത പ്രവർത്തനങ്ങൾ','Customers':'ഉപഭോക്താക്കൾ','Suppliers':'വിതരണക്കാർ','Add Product':'ഉൽപ്പന്നം ചേർക്കുക','Select Customer':'ഉപഭോക്താവിനെ തിരഞ്ഞെടുക്കുക','Select Supplier':'വിതരണക്കാരനെ തിരഞ്ഞെടുക്കുക','Payment mode':'പേയ്മെന്റ് രീതി','Grand Total':'ആകെ തുക','Due':'ബാക്കി','Subtotal':'ഉപമൊത്തം','Discount':'ഇളവ്','Taxable':'നികുതി ബാധകം','GST':'ജിഎസ്ടി','Paid amount':'അടച്ച തുക','New Sales Invoice':'പുതിയ വിൽപ്പന ഇൻവോയ്സ്','New Purchase Invoice':'പുതിയ വാങ്ങൽ ഇൻവോയ്സ്','Sales Invoice':'വിൽപ്പന ഇൻവോയ്സ്','Purchase Invoice':'വാങ്ങൽ ഇൻവോയ്സ്','Select Product':'ഉൽപ്പന്നം തിരഞ്ഞെടുക്കുക','Add Customer':'ഉപഭോക്താവിനെ ചേർക്കുക','Add Supplier':'വിതരണക്കാരനെ ചേർക്കുക','App Language':'ആപ്പ് ഭാഷ',
  },
  'ਪੰਜਾਬੀ': {
    'Home':'ਹੋਮ','Sales':'ਵਿਕਰੀ','Purchase':'ਖਰੀਦ','Parties':'ਪਾਰਟੀਆਂ','More':'ਹੋਰ','Inventory':'ਸਟਾਕ','Payments':'ਭੁਗਤਾਨ','Expenses':'ਖਰਚੇ','Reports & Export':'ਰਿਪੋਰਟਾਂ ਅਤੇ ਐਕਸਪੋਰਟ','Merchant Profile':'ਵਪਾਰੀ ਪ੍ਰੋਫਾਈਲ','Language':'ਭਾਸ਼ਾ','Save':'ਸੇਵ','Cancel':'ਰੱਦ ਕਰੋ','Business Overview':'ਕਾਰੋਬਾਰੀ ਝਲਕ','Total Sales':'ਕੁੱਲ ਵਿਕਰੀ','Collection':'ਵਸੂਲੀ','Profit':'ਮੁਨਾਫਾ','Receivable':'ਲੈਣਾ ਹੈ','Payable':'ਦੇਣਾ ਹੈ','Stock Value':'ਸਟਾਕ ਮੁੱਲ','Business Expenses':'ਕਾਰੋਬਾਰੀ ਖਰਚੇ','Quick Actions':'ਤੁਰੰਤ ਕਾਰਵਾਈਆਂ','Customers':'ਗਾਹਕ','Suppliers':'ਸਪਲਾਇਰ','Add Product':'ਉਤਪਾਦ ਜੋੜੋ','Select Customer':'ਗਾਹਕ ਚੁਣੋ','Select Supplier':'ਸਪਲਾਇਰ ਚੁਣੋ','Payment mode':'ਭੁਗਤਾਨ ਢੰਗ','Grand Total':'ਕੁੱਲ ਰਕਮ','Due':'ਬਕਾਇਆ','Subtotal':'ਉਪ-ਜੋੜ','Discount':'ਛੂਟ','Taxable':'ਟੈਕਸਯੋਗ','GST':'ਜੀਐਸਟੀ','Paid amount':'ਅਦਾ ਕੀਤੀ ਰਕਮ','New Sales Invoice':'ਨਵੀਂ ਵਿਕਰੀ ਇਨਵੌਇਸ','New Purchase Invoice':'ਨਵੀਂ ਖਰੀਦ ਇਨਵੌਇਸ','Sales Invoice':'ਵਿਕਰੀ ਇਨਵੌਇਸ','Purchase Invoice':'ਖਰੀਦ ਇਨਵੌਇਸ','Select Product':'ਉਤਪਾਦ ਚੁਣੋ','Add Customer':'ਗਾਹਕ ਜੋੜੋ','Add Supplier':'ਸਪਲਾਇਰ ਜੋੜੋ','App Language':'ਐਪ ਭਾਸ਼ਾ',
  },
  'অসমীয়া': {
    'Home':'হোম','Sales':'বিক্ৰী','Purchase':'ক্ৰয়','Parties':'পক্ষসমূহ','More':'অধিক','Inventory':'মজুত','Payments':'পেমেণ্ট','Expenses':'খৰচ','Reports & Export':'ৰিপ’ৰ্ট আৰু এক্সপ’ৰ্ট','Merchant Profile':'ব্যৱসায়ী প্ৰফাইল','Language':'ভাষা','Save':'সংৰক্ষণ','Cancel':'বাতিল','Business Overview':'ব্যৱসায়ৰ সাৰাংশ','Total Sales':'মুঠ বিক্ৰী','Collection':'আদায়','Profit':'লাভ','Receivable':'পাবলগীয়া','Payable':'দিবলগীয়া','Stock Value':'ষ্টকৰ মূল্য','Business Expenses':'ব্যৱসায়িক খৰচ','Quick Actions':'দ্ৰুত কাৰ্য','Customers':'গ্ৰাহক','Suppliers':'যোগানদাতা','Add Product':'পণ্য যোগ কৰক','Select Customer':'গ্ৰাহক বাছক','Select Supplier':'যোগানদাতা বাছক','Payment mode':'পেমেণ্ট পদ্ধতি','Grand Total':'মুঠ','Due':'বাকী','Subtotal':'উপমুঠ','Discount':'ৰেহাই','Taxable':'কৰযোগ্য','GST':'জিএছটি','Paid amount':'পৰিশোধ কৰা ধন','New Sales Invoice':'নতুন বিক্ৰী ইনভইচ','New Purchase Invoice':'নতুন ক্ৰয় ইনভইচ','Sales Invoice':'বিক্ৰী ইনভইচ','Purchase Invoice':'ক্ৰয় ইনভইচ','Select Product':'পণ্য বাছক','Add Customer':'গ্ৰাহক যোগ কৰক','Add Supplier':'যোগানদাতা যোগ কৰক','App Language':'এপৰ ভাষা',
  },
};

String tr(String key) => _i18n[appLanguage.value]?[key] ?? _i18n['English']![key] ?? key;

String localeCode(String language) {
  const codes = {
    'English':'en','हिन्दी':'hi','বাংলা':'bn','मराठी':'mr','తెలుగు':'te','தமிழ்':'ta',
    'ગુજરાતી':'gu','اردو':'ur','ಕನ್ನಡ':'kn','ଓଡ଼ିଆ':'or','മലയാളം':'ml','ਪੰਜਾਬੀ':'pa','অসমীয়া':'as',
  };
  return codes[language] ?? 'en';
}

List<Locale> get supportedIndianLocales => const [
  Locale('en'), Locale('hi'), Locale('bn'), Locale('mr'), Locale('te'), Locale('ta'),
  Locale('gu'), Locale('ur'), Locale('kn'), Locale('or'), Locale('ml'), Locale('pa'), Locale('as'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openDatabase(
    p.join(await getDatabasesPath(), 'dokanmate.db'),
    version: 1,
    onCreate: createDb,
  );
  await ensureDb(db);
  final langRows = await db.query('business', columns: ['language'], where: 'id=1');
  if (langRows.isNotEmpty && (langRows.first['language'] ?? '').toString().isNotEmpty) {
    appLanguage.value = langRows.first['language'].toString();
  }
  runApp(DokanMate(db));
}

Future<void> createDb(Database db, int version) async {
  await ensureDb(db);
}

Future<void> ensureDb(Database db) async {
  final tables = <String>[
    'CREATE TABLE IF NOT EXISTS business(id INTEGER PRIMARY KEY, name TEXT, owner TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, upi TEXT, language TEXT DEFAULT "English")',
    'CREATE TABLE IF NOT EXISTS parties(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, type TEXT, balance REAL DEFAULT 0, credit_limit REAL DEFAULT 0, credit_days INTEGER DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, sku TEXT, barcode TEXT, hsn TEXT, unit TEXT, gst REAL DEFAULT 0, buy REAL DEFAULT 0, sell REAL DEFAULT 0, wholesale REAL DEFAULT 0, qty REAL DEFAULT 0, min_qty REAL DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS sales(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL, cost REAL DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL)',
    'CREATE TABLE IF NOT EXISTS payments(id INTEGER PRIMARY KEY AUTOINCREMENT, party_id INTEGER, type TEXT, amount REAL, date TEXT, mode TEXT, reference TEXT)',
    'CREATE TABLE IF NOT EXISTS expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, mode TEXT, note TEXT)',
    'CREATE TABLE IF NOT EXISTS stock_moves(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, type TEXT, qty REAL, date TEXT, reference TEXT)',
    'CREATE TABLE IF NOT EXISTS audit(id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT, date TEXT, details TEXT)'
  ];
  for (final sql in tables) {
    await db.execute(sql);
  }
  final businessCols = await db.rawQuery('PRAGMA table_info(business)');
  if (!businessCols.any((x) => x['name'].toString() == 'language')) {
    await db.execute('ALTER TABLE business ADD COLUMN language TEXT DEFAULT "English"');
  }
  final saleItemCols = await db.rawQuery('PRAGMA table_info(sale_items)');
  if (!saleItemCols.any((x) => x['name'].toString() == 'cost')) {
    await db.execute('ALTER TABLE sale_items ADD COLUMN cost REAL DEFAULT 0');
  }
  final b = await db.query('business', where: 'id=1');
  if (b.isEmpty) {
    await db.insert('business', {
      'id': 1,
      'name': 'My Business',
      'owner': '',
      'phone': '',
      'address': '',
      'state': 'West Bengal',
      'gstin': '',
      'upi': '',
      'language': 'English'
    });
  }
}

String money(num n) => '₹' + n.toStringAsFixed(2);
String stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
String today() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
String prettyDate(Object? value) {
  if (value == null) return '';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(value.toString()));
  } catch (_) {
    return value.toString();
  }
}

class DokanMate extends StatefulWidget {
  final Database db;
  const DokanMate(this.db, {super.key});
  @override
  State<DokanMate> createState() => _DokanMateState();
}

class _DokanMateState extends State<DokanMate> {
  int tab = 0;
  int refreshKey = 0;
  bool intro = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => intro = false);
    });
  }

  void refresh() {
    setState(() {
      refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        if (intro) {
          return const MaterialApp(debugShowCheckedModeBanner: false, home: IntroPage());
        }
        final pages = <Widget>[
      HomePage(widget.db, key: ValueKey('home$refreshKey')),
      SalesPage(widget.db, refresh, key: ValueKey('sales$refreshKey')),
      PurchasePage(widget.db, refresh, key: ValueKey('purchase$refreshKey')),
      PartiesPage(widget.db, refresh, key: ValueKey('party$refreshKey')),
      MorePage(widget.db, refresh, key: ValueKey('more$refreshKey')),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DokanMate',
      locale: Locale(localeCode(lang)),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: supportedIndianLocales,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5CE2)),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: tab, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() {
              tab = value;
            });
          },
          destinations: [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: tr('Home')),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: tr('Sales')),
            NavigationDestination(icon: Icon(Icons.shopping_cart_rounded), label: tr('Purchase')),
            NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: tr('Parties')),
            NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: tr('More')),
          ],
        ),
      ),
        );
      },
    );
  }
}


class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF312E81), Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final eased = Curves.easeOutBack.transform(controller.value);
              return Opacity(
                opacity: controller.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.72 + (0.28 * eased),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92, height: 92,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.16), shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 22),
                      const Text('DokanMate', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: .5)),
                      const SizedBox(height: 10),
                      const Text('Made with love ❤️', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      const Text('Only for you', style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 14)),
                      const SizedBox(height: 34),
                      const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget header(String title, String subtitle, {List<Widget> actions = const []}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF777B86))),
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

Widget statCard(String title, String value, IconData icon) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: .94, end: 1),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
    child: Container(
      padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: const Color(0xFF5B5CE2)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF777B86))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
      ],
    ),
  );
}

Widget emptyState(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.inbox_rounded, size: 42, color: Color(0xFFB0B3BE)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF777B86))),
      ],
    ),
  );
}

Widget quickAction(BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return SizedBox(
    width: 105,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5B5CE2)),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  final Database db;
  const HomePage(this.db, {super.key});

  Future<Map<String, double>> totals() async {
    final sales = (await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(taxable),0) taxable, COALESCE(SUM(paid),0) paid, COALESCE(SUM(due),0) due FROM sales'
    )).first;
    final purchase = (await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(due),0) due FROM purchases'
    )).first;
    final cogs = (await db.rawQuery(
      'SELECT COALESCE(SUM(si.qty * si.cost),0) total FROM sale_items si'
    )).first;
    final expense = (await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) total FROM expenses'
    )).first;
    final stock = (await db.rawQuery(
      'SELECT COALESCE(SUM(qty*buy),0) total FROM products'
    )).first;

    return {
      'sales': (sales['total'] as num).toDouble(),
      'taxableSales': (sales['taxable'] as num).toDouble(),
      'paid': (sales['paid'] as num).toDouble(),
      'receivable': (sales['due'] as num).toDouble(),
      'purchase': (purchase['total'] as num).toDouble(),
      'payable': (purchase['due'] as num).toDouble(),
      'cogs': (cogs['total'] as num).toDouble(),
      'expense': (expense['total'] as num).toDouble(),
      'stock': (stock['total'] as num).toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: totals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final x = snapshot.data!;
        final result = x['taxableSales']! - x['cogs']! - x['expense']!;

        return ListView(
          padding: const EdgeInsets.only(bottom: 25),
          children: [
            header(
              'DokanMate',
              'Modern offline business manager',
              actions: [
                IconButton(
                  onPressed: () => businessDialog(context, db),
                  icon: const Icon(Icons.storefront_rounded),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24264D), Color(0xFF635BDB)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUSINESS OVERVIEW',
                      style: TextStyle(color: Color(0xFFC8C9FF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(money(x['sales']!), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    Text(tr('Total Sales'), style: const TextStyle(color: Color(0xFFD9DBEE))),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _Hero(tr('Collection'), money(x['paid']!))),
                        const SizedBox(width: 8),
                        Expanded(child: _Hero(tr('Profit'), money(result))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
              child: Text(tr('Quick Actions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  quickAction(context, 'New Sale', Icons.add_shopping_cart_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, false, () {})));
                  }),
                  quickAction(context, 'Purchase', Icons.shopping_bag_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, true, () {})));
                  }),
                  quickAction(context, 'Payment In', Icons.call_received_rounded, () => paymentDialog(context, db, true)),
                  quickAction(context, 'Payment Out', Icons.call_made_rounded, () => paymentDialog(context, db, false)),
                  quickAction(context, 'Expense', Icons.account_balance_wallet_rounded, () => expenseDialog(context, db)),
                  quickAction(context, 'Product', Icons.inventory_2_rounded, () => productDialog(context, db)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
              child: Text(tr('Business Overview'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  statCard(tr('Receivable'), money(x['receivable']!), Icons.account_balance_wallet_rounded),
                  statCard(tr('Payable'), money(x['payable']!), Icons.request_quote_rounded),
                  statCard(tr('Stock Value'), money(x['stock']!), Icons.inventory_2_rounded),
                  statCard(tr('Business Expenses'), money(x['expense']!), Icons.money_off_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String value;
  const _Hero(this.title, this.value);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFD2D4E8), fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class SalesPage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const SalesPage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, false, refresh))),
            icon: const Icon(Icons.add_circle_rounded),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.rawQuery('SELECT s.*, p.name party FROM sales s LEFT JOIN parties p ON p.id=s.party_id ORDER BY s.id DESC'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Padding(padding: const EdgeInsets.all(18), child: emptyState('No sales yet', 'Create an item-based sales invoice.'));
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: rows.map((x) {
              return Card(
                child: ListTile(
                  onTap: () => invoicePdf(context, db, (x['id'] as num).toInt(), false),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8F85FF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                  ),
                  title: Text(x['invoice'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text((x['party'] ?? 'Walk-in').toString() + ' • ' + prettyDate(x['date'])),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(x['total'] as num), style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        (x['due'] as num) > 0 ? 'Due ' + money(x['due'] as num) : 'Paid',
                        style: TextStyle(fontSize: 10, color: (x['due'] as num) > 0 ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PurchasePage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const PurchasePage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, true, refresh))),
            icon: const Icon(Icons.add_circle_rounded),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.rawQuery('SELECT s.*, p.name party FROM purchases s LEFT JOIN parties p ON p.id=s.party_id ORDER BY s.id DESC'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Padding(padding: const EdgeInsets.all(18), child: emptyState('No purchases yet', 'Create purchase invoices and stock will update automatically.'));
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: rows.map((x) {
              return Card(
                child: ListTile(
                  onTap: () => invoicePdf(context, db, (x['id'] as num).toInt(), true),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF13B981), Color(0xFF58D7AE)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                  ),
                  title: Text(x['invoice'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text((x['party'] ?? 'Supplier').toString() + ' • ' + prettyDate(x['date'])),
                  trailing: Text(money(x['total'] as num), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class InvoiceLine {
  final int productId;
  final String name;
  final String unit;
  final double rate;
  final double gst;
  double qty;
  double discount;
  InvoiceLine(this.productId, this.name, this.unit, this.rate, this.gst, this.qty, this.discount);
  double get base => qty * rate - discount;
  double get tax => base * gst / 100;
  double get total => base + tax;
}

class InvoicePage extends StatefulWidget {
  final Database db;
  final bool purchase;
  final VoidCallback refresh;
  const InvoicePage(this.db, this.purchase, this.refresh, {super.key});
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Map<String, Object?>> parties = [];
  List<Map<String, Object?>> products = [];
  List<InvoiceLine> lines = [];
  int? partyId;
  String mode = '';
  final paid = TextEditingController();

  double get subtotal => lines.fold(0, (sum, line) => sum + line.qty * line.rate);
  double get discount => lines.fold(0, (sum, line) => sum + line.discount);
  double get taxable => lines.fold(0, (sum, line) => sum + line.base);
  double get gstTotal => lines.fold(0, (sum, line) => sum + line.tax);
  double get total => taxable + gstTotal;
  double get paidAmount => double.tryParse(paid.text) ?? 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final pRows = await widget.db.query(
      'parties',
      where: "LOWER(type)=LOWER(?) OR LOWER(type)='both'",
      whereArgs: [widget.purchase ? 'supplier' : 'customer'],
      orderBy: 'name',
    );
    final productRows = await widget.db.query('products', orderBy: 'name');
    if (mounted) {
      setState(() {
        parties = pRows;
        products = productRows;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.purchase ? 'New Purchase Invoice' : 'New Sales Invoice'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.purchase
                    ? const [Color(0xFF0E8F6E), Color(0xFF42C7A1)]
                    : const [Color(0xFF4F46E5), Color(0xFF8B7FFF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(.18),
                  child: Icon(widget.purchase ? Icons.shopping_bag_rounded : Icons.receipt_long_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(widget.purchase ? 'Purchase Invoice' : 'Sales Invoice'),
                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _label(widget.purchase ? tr('Select Supplier') : tr('Select Customer')),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await partyPicker(context, widget.db, widget.purchase ? 'supplier' : 'customer');
                if (picked != null && mounted) setState(() => partyId = picked);
              },
              icon: const Icon(Icons.person_search_rounded),
              label: Text(partyId == null ? tr(widget.purchase ? 'Select Supplier' : 'Select Customer') : (parties.firstWhere((p) => p['id'] == partyId, orElse: () => {'name': 'Selected Party'})['name']?.toString() ?? 'Selected Party')),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: widget.purchase ? 'Add Supplier' : 'Add Customer',
              onPressed: () async { await partyDialog(context, widget.db, widget.purchase ? 'supplier' : 'customer'); await load(); },
              icon: const Icon(Icons.add_rounded),
            ),
          ]),
          const SizedBox(height: 18),
          _label('ITEMS'),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: products.isEmpty ? () => productDialog(context, widget.db, onSaved: load) : selectProduct,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(products.isEmpty ? 'Add Product First' : tr('Add Product')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Create new product',
                onPressed: () async {
                  await productDialog(context, widget.db, onSaved: load);
                  await load();
                },
                icon: const Icon(Icons.add_box_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lines.isEmpty) emptyState('No items', 'Add product, quantity, rate, discount and GST.'),
          ...lines.asMap().entries.map((entry) => lineCard(entry.key, entry.value)),
          const SizedBox(height: 12),
          _label('PAYMENT'),
          TextField(
            controller: paid,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Paid amount')),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: mode.isEmpty ? null : mode,
            decoration: InputDecoration(labelText: '${tr('Payment mode')} *', hintText: tr('Payment mode'), prefixIcon: const Icon(Icons.payments_rounded)),
            items: ['Cash', 'UPI', 'Bank', 'Card', 'Cheque', 'Credit'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (value) => setState(() => mode = value ?? ''),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _sum(tr('Subtotal'), money(subtotal)),
                _sum(tr('Discount'), money(discount)),
                _sum(tr('Taxable'), money(taxable)),
                _sum(tr('GST'), money(gstTotal)),
                const Divider(),
                _sum(tr('Grand Total'), money(total), bold: true),
                _sum(tr('Due'), money((total - paidAmount).clamp(0, double.infinity)), color: Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: saveInvoice,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Invoice'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ],
      ),
    );
  }

  Widget lineCard(int index, InvoiceLine line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(line.name, style: const TextStyle(fontWeight: FontWeight.w800))),
              IconButton(
                onPressed: () => setState(() => lines.removeAt(index)),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _numberField('Qty ' + line.unit, line.qty, (v) => line.qty = v)),
              const SizedBox(width: 7),
              Expanded(child: _numberField('Rate', line.rate, null, enabled: false)),
              const SizedBox(width: 7),
              Expanded(child: _numberField('Discount', line.discount, (v) => line.discount = v)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(money(line.total), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _numberField(String label, double value, void Function(double)? onChanged, {bool enabled = true}) {
    return TextFormField(
      key: ValueKey(label),
      enabled: enabled,
      initialValue: value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        if (onChanged != null) {
          onChanged(double.tryParse(v) ?? 0);
          setState(() {});
        }
      },
    );
  }

  Future<void> selectProduct() async {
    final chosen = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Select Product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...products.map((p) {
              final price = widget.purchase ? p['buy'] as num : p['sell'] as num;
              return ListTile(
                title: Text(p['name'].toString()),
                subtitle: Text(p['unit'].toString() + ' • GST ' + p['gst'].toString() + '% • Stock ' + p['qty'].toString()),
                trailing: Text(money(price)),
                onTap: () => Navigator.pop(sheetContext, p),
              );
            }),
          ],
        );
      },
    );
    if (chosen != null) {
      final price = widget.purchase ? chosen['buy'] as num : chosen['sell'] as num;
      final existing = lines.indexWhere((line) => line.productId == (chosen['id'] as int));
      setState(() {
        if (existing >= 0) {
          lines[existing].qty += 1;
        } else {
          lines.add(InvoiceLine(
            chosen['id'] as int,
            chosen['name'].toString(),
            chosen['unit'].toString(),
            price.toDouble(),
            (chosen['gst'] as num).toDouble(),
            1,
            0,
          ));
        }
      });
    }
  }

  Future<void> saveInvoice() async {
    if (lines.isEmpty) {
      showMsg(context, 'Add at least one product.');
      return;
    }
    if (mode.isEmpty) {
      showMsg(context, 'Please select a payment mode.');
      return;
    }
    if (mode == 'Credit' && partyId == null) {
      showMsg(context, 'Credit sale/purchase requires a customer or supplier.');
      return;
    }
    if (paidAmount < 0 || paidAmount > total) {
      showMsg(context, 'Paid amount cannot exceed invoice total.');
      return;
    }
    for (final line in lines) {
      if (line.qty <= 0) {
        showMsg(context, 'Quantity must be greater than zero.');
        return;
      }
      if (line.discount < 0 || line.discount > line.qty * line.rate) {
        showMsg(context, 'Discount cannot be greater than the line value.');
        return;
      }
    }

    final business = (await widget.db.query('business', where: 'id=1')).first;
    String partyState = business['state'].toString();
    if (partyId != null) {
      final pRows = await widget.db.query('parties', where: 'id=?', whereArgs: [partyId]);
      if (pRows.isNotEmpty) partyState = pRows.first['state'].toString();
    }

    if (!widget.purchase) {
      for (final line in lines) {
        final rows = await widget.db.query('products', columns: ['qty'], where: 'id=?', whereArgs: [line.productId]);
        final available = rows.isEmpty ? 0.0 : ((rows.first['qty'] as num?) ?? 0).toDouble();
        if (line.qty > available + 0.000001) {
          showMsg(context, 'Not enough stock for ${line.name}. Available: ${available.toStringAsFixed(2)} ${line.unit}');
          return;
        }
      }
    }

    final sameState = business['state'].toString().trim().toLowerCase() == partyState.trim().toLowerCase();
    final cgst = sameState ? gstTotal / 2 : 0.0;
    final sgst = sameState ? gstTotal / 2 : 0.0;
    final igst = sameState ? 0.0 : gstTotal;
    final table = widget.purchase ? 'purchases' : 'sales';
    final itemTable = widget.purchase ? 'purchase_items' : 'sale_items';
    final itemKey = widget.purchase ? 'purchase_id' : 'sale_id';
    final maxIdRows = await widget.db.rawQuery('SELECT COALESCE(MAX(id),0) AS last_id FROM ' + table);
    final nextNumber = ((maxIdRows.first['last_id'] as num?) ?? 0).toInt() + 1;
    final invoice = (widget.purchase ? 'PUR-' : 'INV-') + nextNumber.toString().padLeft(5, '0');
    final due = (total - paidAmount).clamp(0.0, double.infinity);

    await widget.db.transaction((tx) async {
      final id = await tx.insert(table, {
        'invoice': invoice,
        'date': today(),
        'party_id': partyId,
        'subtotal': subtotal,
        'discount': discount,
        'taxable': taxable,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'total': total,
        'paid': paidAmount,
        'due': due,
        'mode': mode,
      });

      for (final line in lines) {
        final productRows = await tx.query('products', columns: ['buy'], where: 'id=?', whereArgs: [line.productId]);
        final cost = productRows.isEmpty ? 0.0 : ((productRows.first['buy'] as num?) ?? 0).toDouble();
        await tx.insert(itemTable, {
          itemKey: id,
          'product_id': line.productId,
          'name': line.name,
          'qty': line.qty,
          'unit': line.unit,
          'rate': line.rate,
          'discount': line.discount,
          'gst': line.gst,
          'amount': line.total,
          if (!widget.purchase) 'cost': cost,
        });
        final delta = widget.purchase ? line.qty : -line.qty;
        await tx.rawUpdate('UPDATE products SET qty=qty+? WHERE id=?', [delta, line.productId]);
        await tx.insert('stock_moves', {
          'product_id': line.productId,
          'type': widget.purchase ? 'PURCHASE' : 'SALE',
          'qty': delta,
          'date': today(),
          'reference': invoice,
        });
      }

      if (partyId != null && due > 0) {
        await tx.rawUpdate('UPDATE parties SET balance=balance+? WHERE id=?', [due, partyId]);
      }
      if (partyId != null && paidAmount > 0) {
        await tx.insert('payments', {
          'party_id': partyId,
          'type': widget.purchase ? 'OUT' : 'IN',
          'amount': paidAmount,
          'date': today(),
          'mode': mode,
          'reference': invoice,
        });
      }
      await tx.insert('audit', {'action': widget.purchase ? 'Purchase' : 'Sale', 'date': today(), 'details': invoice});
    });

    if (mounted) {
      widget.refresh();
      Navigator.pop(context);
      await showMsg(context, 'Invoice ' + invoice + ' saved successfully.');
    }
  }
}

Widget _label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7, left: 2),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF777B86), letterSpacing: 1.1)),
  );
}

Widget _sum(String a, String b, {bool bold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: TextStyle(color: color ?? const Color(0xFF70747F))),
        Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color)),
      ],
    ),
  );
}

class PartiesPage extends StatefulWidget {
  final Database db;
  final VoidCallback refresh;
  const PartiesPage(this.db, this.refresh, {super.key});
  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  bool customer = true;

  @override
  Widget build(BuildContext context) {
    final type = customer ? 'customer' : 'supplier';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => partyDialog(context, widget.db, type), icon: const Icon(Icons.person_add_alt_1_rounded))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Customers')),
                ButtonSegment(value: false, label: Text('Suppliers')),
              ],
              selected: {customer},
              onSelectionChanged: (value) => setState(() => customer = value.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: widget.db.query('parties', where: 'type=?', whereArgs: [type], orderBy: 'name'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(18),
                    child: emptyState(customer ? 'No customers' : 'No suppliers', 'Add parties to track credit and payments.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final x = rows[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEEF0FF),
                          child: Icon(customer ? Icons.person : Icons.factory, color: const Color(0xFF5B5CE2)),
                        ),
                        title: Text(x['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text((x['phone'] ?? '').toString() + ' • ' + (x['gstin'] ?? '').toString()),
                        trailing: Text(money((x['balance'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const MorePage(this.db, this.refresh, {super.key});

  Widget menu(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF5B5CE2)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        header(tr('More'), 'Inventory, reports, GST and business tools'),
        menu(tr('Inventory'), 'Products, units, stock and low-stock alerts', Icons.inventory_2_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryPage(db, refresh)));
        }),
        menu(tr('Payments'), 'Payment In, Payment Out and ledger', Icons.payments_rounded, () => paymentsPage(context, db)),
        menu(tr('Expenses'), 'Rent, salary, transport and other expenses', Icons.account_balance_wallet_rounded, () => expenseDialog(context, db)),
        menu('Reports & Export', 'PDF, Excel and CSV', Icons.analytics_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsPage(db)));
        }),
        menu(tr('Merchant Profile'), 'Store name, owner, phone, address, state, GSTIN and UPI — used on invoices', Icons.storefront_rounded, () => businessDialog(context, db)),
        menu(tr('Language'), 'English / বাংলা / हिन्दी', Icons.translate_rounded, () => languageDialog(context, db)),
        menu('Backup & Restore', 'Offline data backup', Icons.backup_rounded, () => showMsg(context, 'Backup and restore will be added next.')),
        menu('PIN / Biometric', 'Protect business data', Icons.lock_rounded, () => showMsg(context, 'PIN and biometric protection will be added next.')),
      ],
    );
  }
}

class InventoryPage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const InventoryPage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () => productDialog(context, db, onSaved: refresh), icon: const Icon(Icons.add_circle_rounded))],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.query('products', orderBy: 'name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(18), child: emptyState('No products', 'Add KG, PCS, GM, Litre, Box and other units.'));
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final x = rows[index];
              final qty = (x['qty'] as num?) ?? 0;
              final low = qty <= ((x['min_qty'] as num?) ?? 0);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: low ? const Color(0xFFFFE8E8) : const Color(0xFFEEF0FF),
                    child: Icon(Icons.inventory_2_rounded, color: low ? Colors.red : const Color(0xFF5B5CE2)),
                  ),
                  title: Text(x['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(x['unit'].toString() + ' • GST ' + x['gst'].toString() + '% • HSN ' + x['hsn'].toString()),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(qty.toStringAsFixed(2) + ' ' + x['unit'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(money((x['sell'] as num?) ?? 0), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> productDialog(BuildContext context, Database db, {VoidCallback? onSaved}) async {
  final name = TextEditingController();
  final sku = TextEditingController();
  final hsn = TextEditingController();
  final stock = TextEditingController(text: '0');
  final buy = TextEditingController(text: '0');
  final sell = TextEditingController(text: '0');
  final gst = TextEditingController(text: '0');
  final min = TextEditingController(text: '0');
  String unit = 'PCS';

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Product name *', prefixIcon: Icon(Icons.inventory_2_rounded))),
                  const SizedBox(height: 8),
                  TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU / Barcode', prefixIcon: Icon(Icons.qr_code_2_rounded))),
                  const SizedBox(height: 8),
                  TextField(controller: hsn, decoration: const InputDecoration(labelText: 'HSN/SAC', prefixIcon: Icon(Icons.tag_rounded))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Measurement unit', prefixIcon: Icon(Icons.straighten_rounded)),
                    items: const ['PCS','KG','GM','MG','LITRE','ML','METER','CM','BOX','PACKET','BAG','BOTTLE','DOZEN','PAIR','SET']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => unit = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: stock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Opening stock'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: min, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Low stock alert'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: buy, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase price'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: sell, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: gst, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'GST %', prefixIcon: Icon(Icons.percent_rounded))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('Cancel'))),
              FilledButton.icon(
                onPressed: () async {
                  final productName = name.text.trim();
                  final skuValue = sku.text.trim();
                  final opening = double.tryParse(stock.text.trim()) ?? 0;
                  final buyValue = double.tryParse(buy.text.trim()) ?? 0;
                  final sellValue = double.tryParse(sell.text.trim()) ?? 0;
                  final gstValue = double.tryParse(gst.text.trim()) ?? 0;
                  final minValue = double.tryParse(min.text.trim()) ?? 0;
                  if (productName.isEmpty) {
                    showMsg(dialogContext, 'Product name is required.');
                    return;
                  }
                  if (opening < 0 || buyValue < 0 || sellValue < 0 || gstValue < 0 || minValue < 0) {
                    showMsg(dialogContext, 'Numbers cannot be negative.');
                    return;
                  }
                  if (skuValue.isNotEmpty) {
                    final duplicate = await db.query('products', where: 'sku=? OR barcode=?', whereArgs: [skuValue, skuValue], limit: 1);
                    if (duplicate.isNotEmpty) {
                      showMsg(dialogContext, 'This SKU / Barcode already exists. Use a different one.');
                      return;
                    }
                  }
                  await db.insert('products', {
                    'name': productName,
                    'sku': skuValue,
                    'barcode': skuValue,
                    'hsn': hsn.text.trim(),
                    'unit': unit,
                    'gst': gstValue,
                    'buy': buyValue,
                    'sell': sellValue,
                    'wholesale': 0,
                    'qty': opening,
                    'min_qty': minValue,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  onSaved?.call();
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(tr('Save')),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<int?> partyPicker(BuildContext context, Database db, String type) async {
  final rows = await db.query('parties', where: "LOWER(type)=LOWER(?) OR LOWER(type)='both'", whereArgs: [type], orderBy: 'name');
  String query = '';
  return showDialog<int?>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final filtered = rows.where((p) {
          final q = query.toLowerCase().trim();
          return q.isEmpty || p['name'].toString().toLowerCase().contains(q) || p['phone'].toString().toLowerCase().contains(q);
        }).toList();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(tr(type == 'supplier' ? 'Select Supplier' : 'Select Customer'), style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 420, height: 420,
            child: Column(children: [
              TextField(autofocus: true, decoration: const InputDecoration(hintText: 'Search by name or phone', prefixIcon: Icon(Icons.search_rounded)), onChanged: (v) => setDialogState(() => query = v)),
              const SizedBox(height: 10),
              Expanded(child: filtered.isEmpty
                ? Center(child: Text('No ${type == 'supplier' ? 'supplier' : 'customer'} found. Tap + to add one.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = filtered[i]; final n = p['name'].toString();
                      return ListTile(
                        leading: CircleAvatar(child: Text(n.isEmpty ? '?' : n.substring(0, 1).toUpperCase())),
                        title: Text(n, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text((p['phone'] ?? '').toString()),
                        onTap: () => Navigator.pop(dialogContext, p['id'] as int),
                      );
                    },
                  )),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('Cancel')))],
        );
      },
    ),
  );
}

Future<void> partyDialog(BuildContext context, Database db, String type) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final state = TextEditingController(text: 'West Bengal');
  final gstin = TextEditingController();
  final limit = TextEditingController();
  final days = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(type == 'customer' ? 'New Customer' : 'New Supplier'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: state, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: gstin, decoration: const InputDecoration(labelText: 'GSTIN')),
              TextField(controller: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Credit limit')),
              TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit days')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await db.insert('parties', {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'address': address.text.trim(),
                'state': state.text.trim(),
                'gstin': gstin.text.trim(),
                'type': type,
                'balance': 0,
                'credit_limit': double.tryParse(limit.text) ?? 0,
                'credit_days': int.tryParse(days.text) ?? 0,
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> paymentDialog(BuildContext context, Database db, bool incoming) async {
  final type = incoming ? 'customer' : 'supplier';
  final rows = await db.query('parties', where: 'type=?', whereArgs: [type], orderBy: 'name');
  if (!context.mounted) return;
  int? party;
  String mode = 'Cash';
  final amount = TextEditingController();
  final reference = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(incoming ? 'Payment In' : 'Payment Out'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: party,
                  decoration: InputDecoration(labelText: incoming ? 'Customer' : 'Supplier'),
                  items: rows.map((x) => DropdownMenuItem<int?>(value: x['id'] as int, child: Text(x['name'].toString()))).toList(),
                  onChanged: (value) => setDialogState(() => party = value),
                ),
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Payment mode'),
                  items: ['Cash','UPI','Bank','Card','Cheque'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => mode = value!),
                ),
                TextField(controller: reference, decoration: const InputDecoration(labelText: 'Reference')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0) return;
                  await db.insert('payments', {'party_id': party, 'type': incoming ? 'IN' : 'OUT', 'amount': value, 'date': today(), 'mode': mode, 'reference': reference.text});
                  if (party != null) {
                    await db.rawUpdate('UPDATE parties SET balance=balance-? WHERE id=?', [value, party]);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> expenseDialog(BuildContext context, Database db) async {
  String category = 'Other';
  String mode = 'Cash';
  final amount = TextEditingController();
  final note = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Business Expense'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Rent','Electricity','Salary','Transport','Packaging','Advertisement','Internet','Maintenance','Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => category = value!),
                ),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Payment mode'),
                  items: ['Cash','UPI','Bank','Card'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => mode = value!),
                ),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0) return;
                  await db.insert('expenses', {'category': category, 'amount': value, 'date': today(), 'mode': mode, 'note': note.text});
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class ReportsPage extends StatelessWidget {
  final Database db;
  const ReportsPage(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _report(context, 'Business Summary', 'Sales, purchase, due, expenses and result', Icons.analytics_rounded, () => exportPdf(context, db)),
          _report(context, 'Excel Workbook', 'Sales, purchase, parties, products, payments and expenses', Icons.table_chart_rounded, () => exportExcel(context, db)),
          _report(context, 'CSV Export', 'Portable business data', Icons.data_object_rounded, () => exportCsv(context, db)),
          _report(context, 'PDF Report', 'A4 printable report', Icons.picture_as_pdf_rounded, () => exportPdf(context, db)),
        ],
      ),
    );
  }

  Widget _report(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF5B5CE2)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

Future<Directory> exportFolder() async {
  final base = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(base.path, 'DokanMate_Exports'));
  if (!await folder.exists()) await folder.create(recursive: true);
  return folder;
}

Future<void> shareFile(String path, String text) async {
  await Share.shareXFiles([XFile(path)], text: text);
}

CellValue excelValue(Object? value) {
  if (value == null) return TextCellValue('');
  if (value is int) return IntCellValue(value);
  if (value is num) return DoubleCellValue(value.toDouble());
  return TextCellValue(value.toString());
}

Future<void> exportExcel(BuildContext context, Database db) async {
  try {
    final book = Excel.createExcel();
    final tables = ['sales','purchases','parties','products','payments','expenses','stock_moves'];
    for (final table in tables) {
      final rows = await db.query(table);
      final sheet = book[table];
      if (rows.isEmpty) {
        sheet.appendRow([TextCellValue('No data')]);
        continue;
      }
      final keys = rows.first.keys.toList();
      sheet.appendRow(keys.map((x) => TextCellValue(x)).toList());
      for (final row in rows) {
        sheet.appendRow(keys.map((key) => excelValue(row[key])).toList());
      }
    }
    final bytes = book.save();
    if (bytes == null) throw Exception('Excel creation failed');
    final file = File(p.join((await exportFolder()).path, 'DokanMate_' + stamp() + '.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    await shareFile(file.path, 'DokanMate Excel export');
    showMsg(context, 'Excel file created successfully.');
  } catch (e) {
    showMsg(context, 'Excel export failed: ' + e.toString());
  }
}

Future<void> exportCsv(BuildContext context, Database db) async {
  try {
    final buffer = StringBuffer();
    final tables = ['sales','purchases','parties','products','payments','expenses','stock_moves'];
    for (final table in tables) {
      final rows = await db.query(table);
      buffer.writeln(table.toUpperCase());
      if (rows.isEmpty) {
        buffer.writeln('No data');
        continue;
      }
      final keys = rows.first.keys.toList();
      buffer.writeln(keys.join(','));
      for (final row in rows) {
        buffer.writeln(keys.map((key) {
          final value = (row[key] ?? '').toString().replaceAll('"', '""');
          return '"' + value + '"';
        }).join(','));
      }
      buffer.writeln();
    }
    final file = File(p.join((await exportFolder()).path, 'DokanMate_' + stamp() + '.csv'));
    await file.writeAsString(buffer.toString(), flush: true);
    await shareFile(file.path, 'DokanMate CSV export');
    showMsg(context, 'CSV file created successfully.');
  } catch (e) {
    showMsg(context, 'CSV export failed: ' + e.toString());
  }
}

Future<void> exportPdf(BuildContext context, Database db) async {
  try {
    final s = (await db.rawQuery('SELECT COALESCE(SUM(total),0) sales, COALESCE(SUM(taxable),0) taxable, COALESCE(SUM(paid),0) paid, COALESCE(SUM(due),0) due FROM sales')).first;
    final pch = (await db.rawQuery('SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(due),0) due FROM purchases')).first;
    final cogs = (await db.rawQuery('SELECT COALESCE(SUM(qty * cost),0) total FROM sale_items')).first;
    final ex = (await db.rawQuery('SELECT COALESCE(SUM(amount),0) total FROM expenses')).first;
    final result = (s['taxable'] as num).toDouble() - (cogs['total'] as num).toDouble() - (ex['total'] as num).toDouble();
    final pdfFont = await PdfGoogleFonts.notoSansRegular();
    final pdfBold = await PdfGoogleFonts.notoSansBold();
    final pdfTheme = pw.ThemeData.withFont(base: pdfFont, bold: pdfBold);
    final doc = pw.Document(theme: pdfTheme);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return [
            pw.Text('DokanMate Business Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Amount'],
              data: [
                ['Sales', money(s['sales'] as num)],
                ['Collection', money(s['paid'] as num)],
                ['Receivable', money(s['due'] as num)],
                ['Purchase', money(pch['total'] as num)],
                ['Payable', money(pch['due'] as num)],
                ['Expenses', money(ex['total'] as num)],
                ['Profit (sales - COGS - expenses)', money(result)],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('DokanMate offline business manager'),
          ];
        },
      ),
    );

    final file = File(p.join((await exportFolder()).path, 'DokanMate_Report_' + stamp() + '.pdf'));
    await file.writeAsBytes(await doc.save(), flush: true);
    await shareFile(file.path, 'DokanMate PDF report');
    showMsg(context, 'PDF report created successfully.');
  } catch (e) {
    showMsg(context, 'PDF export failed: ' + e.toString());
  }
}

Future<void> invoicePdf(BuildContext context, Database db, int id, bool purchase) async {
  try {
    final table = purchase ? 'purchases' : 'sales';
    final itemTable = purchase ? 'purchase_items' : 'sale_items';
    final itemKey = purchase ? 'purchase_id' : 'sale_id';
    final rows = await db.rawQuery(
      'SELECT x.*, p.name party, p.phone party_phone, p.address party_address, p.gstin party_gstin, p.state party_state FROM ' +
      table + ' x LEFT JOIN parties p ON p.id=x.party_id WHERE x.id=?',
      [id],
    );
    if (rows.isEmpty) return;
    final x = rows.first;
    final items = await db.query(itemTable, where: itemKey + '=?', whereArgs: [id]);
    final business = (await db.query('business', where: 'id=1')).first;

    final primary = PdfColor.fromHex('#5B5CE2');
    final secondary = PdfColor.fromHex('#13B981');
    final soft = PdfColor.fromHex('#F4F5FF');
    final ink = PdfColor.fromHex('#202235');
    final muted = PdfColor.fromHex('#6F7382');

    final doc = pw.Document();
    final pdfFont = await PdfGoogleFonts.notoSansRegular();
    final pdfBold = await PdfGoogleFonts.notoSansBold();
    final pdfTheme = pw.ThemeData.withFont(base: pdfFont, bold: pdfBold);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(business['name'].toString(), style: pw.TextStyle(fontSize: 8, color: muted)),
              pw.Text('Page ${ctx.pageNumber}', style: pw.TextStyle(fontSize: 8, color: muted)),
            ],
          ),
        ),
        build: (_) {
          final partyName = (x['party'] ?? (purchase ? 'Supplier' : 'Walk-in Customer')).toString();
          final gstValue = ((x['cgst'] as num) + (x['sgst'] as num) + (x['igst'] as num));
          final partyLines = <String>[
            partyName,
            if ((x['party_phone'] ?? '').toString().isNotEmpty) 'Phone: ${x['party_phone']}',
            if ((x['party_address'] ?? '').toString().isNotEmpty) x['party_address'].toString(),
            if ((x['party_gstin'] ?? '').toString().isNotEmpty) 'GSTIN: ${x['party_gstin']}',
          ];

          return [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(14)),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(business['name'].toString(), style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        if ((business['owner'] ?? '').toString().isNotEmpty)
                          pw.Text('Owner: ${business['owner']}', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                        if ((business['address'] ?? '').toString().isNotEmpty)
                          pw.Text(business['address'].toString(), style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                        pw.Text('Phone: ${business['phone'] ?? ''}  •  State: ${business['state'] ?? ''}', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                        if ((business['gstin'] ?? '').toString().isNotEmpty)
                          pw.Text('GSTIN: ${business['gstin']}', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                        if ((business['upi'] ?? '').toString().isNotEmpty)
                          pw.Text('UPI: ${business['upi']}', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(purchase ? 'PURCHASE' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primary)),
                        pw.SizedBox(height: 4),
                        pw.Text(x['invoice'].toString(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink)),
                        pw.Text(prettyDate(x['date']), style: pw.TextStyle(fontSize: 8, color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(purchase ? 'SUPPLIER' : 'BILL TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primary)),
                        pw.SizedBox(height: 5),
                        ...partyLines.map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 9, color: ink))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: secondary)),
                        pw.SizedBox(height: 5),
                        pw.Text('Mode: ${x['mode'] ?? ''}', style: pw.TextStyle(fontSize: 9, color: ink)),
                        pw.Text('Paid: ${money(x['paid'] as num)}', style: pw.TextStyle(fontSize: 9, color: ink)),
                        pw.Text('Due: ${money(x['due'] as num)}', style: pw.TextStyle(fontSize: 9, color: ink)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .6),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.8),
                1: pw.FlexColumnWidth(1.0),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primary),
                  children: ['Item', 'Qty', 'Rate', 'GST', 'Amount'].map(
                    (h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                  ).toList(),
                ),
                ...items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final bg = entry.key.isEven ? PdfColors.white : soft;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(item['name'].toString(), style: pw.TextStyle(fontSize: 8, color: ink))),
                      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text('${item['qty']} ${item['unit']}', style: pw.TextStyle(fontSize: 8, color: ink))),
                      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(money(item['rate'] as num), style: pw.TextStyle(fontSize: 8, color: ink))),
                      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text('${item['gst']}%', style: pw.TextStyle(fontSize: 8, color: ink))),
                      pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(money(item['amount'] as num), style: pw.TextStyle(fontSize: 8, color: ink))),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.Text(
                      'GST breakup:  CGST ${money(x['cgst'] as num)}   •   SGST ${money(x['sgst'] as num)}   •   IGST ${money(x['igst'] as num)}',
                      style: pw.TextStyle(fontSize: 8, color: ink),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Container(
                  width: 190,
                  padding: const pw.EdgeInsets.all(13),
                  decoration: pw.BoxDecoration(color: ink, borderRadius: pw.BorderRadius.circular(10)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text('Subtotal  ${money(x['subtotal'] as num)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                      pw.Text('Discount  ${money(x['discount'] as num)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                      pw.Text('Tax  ${money(gstValue)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                      pw.Divider(color: PdfColors.white),
                      pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300, fontWeight: pw.FontWeight.bold)),
                      pw.Text(money(x['total'] as num), style: pw.TextStyle(fontSize: 18, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('Thank you for your business. Please keep this invoice for your records.', style: pw.TextStyle(fontSize: 8, color: muted)),
            ),
          ];
        },
      ),
    );

    final file = File(p.join((await exportFolder()).path, x['invoice'].toString() + '.pdf'));
    await file.writeAsBytes(await doc.save(), flush: true);
    await shareFile(file.path, 'DokanMate invoice ' + x['invoice'].toString());
  } catch (e) {
    showMsg(context, 'Invoice PDF failed: ' + e.toString());
  }
}

Future<void> paymentsPage(BuildContext context, Database db) async {
  final rows = await db.rawQuery(
    'SELECT p.*, q.name party FROM payments p LEFT JOIN parties q ON q.id=p.party_id ORDER BY p.id DESC'
  );
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryPage(rows)));
}

class PaymentHistoryPage extends StatelessWidget {
  final List<Map<String, Object?>> rows;
  const PaymentHistoryPage(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (rows.isEmpty) emptyState('No payments', 'Payment In and Payment Out will appear here.'),
          ...rows.map((x) => Card(
            child: ListTile(
              title: Text((x['party'] ?? 'Account').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text((x['type'] ?? '').toString() + ' • ' + (x['mode'] ?? '').toString()),
              trailing: Text(money((x['amount'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          )),
        ],
      ),
    );
  }
}

Future<void> languageDialog(BuildContext context, Database db) async {
  String selected = appLanguage.value;
  const languages = ['English','हिन्दी','বাংলা','मराठी','తెలుగు','தமிழ்','ગુજરાતી','اردو','ಕನ್ನಡ','ଓଡ଼ିଆ','മലയാളം','ਪੰਜਾਬੀ','অসমীয়া'];
  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(width: 360, height: 440, child: ListView(
          children: languages.map((lang) => RadioListTile<String>(
            value: lang, groupValue: selected, title: Text(lang),
            onChanged: (value) async {
              if (value == null) return;
              setDialogState(() => selected = value);
              appLanguage.value = value;
              await db.update('business', {'language': value}, where: 'id=1');
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
          )).toList(),
        )),
      ),
    ),
  );
}

Future<void> businessDialog(BuildContext context, Database db) async {
  final b = (await db.query('business', where: 'id=1')).first;
  final name = TextEditingController(text: b['name'].toString());
  final owner = TextEditingController(text: b['owner'].toString());
  final phone = TextEditingController(text: b['phone'].toString());
  final address = TextEditingController(text: b['address'].toString());
  final state = TextEditingController(text: b['state'].toString());
  final gstin = TextEditingController(text: b['gstin'].toString());
  final upi = TextEditingController(text: b['upi'].toString());

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr('Merchant Profile'), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Store / Business name', prefixIcon: Icon(Icons.storefront_rounded))),
              TextField(controller: owner, decoration: const InputDecoration(labelText: 'Owner / Merchant name', prefixIcon: Icon(Icons.person_rounded))),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Business phone', prefixIcon: Icon(Icons.phone_rounded))),
              TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Full business address', prefixIcon: Icon(Icons.location_on_rounded))),
              TextField(controller: state, decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_rounded))),
              TextField(controller: gstin, decoration: const InputDecoration(labelText: 'GSTIN', prefixIcon: Icon(Icons.verified_rounded))),
              TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID', prefixIcon: Icon(Icons.account_balance_rounded))),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('These details will appear automatically on Sales and Purchase invoice PDFs.', style: TextStyle(fontSize: 11, color: Color(0xFF777B86))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await db.update('business', {
                'name': name.text,
                'owner': owner.text,
                'phone': phone.text,
                'address': address.text,
                'state': state.text,
                'gstin': gstin.text,
                'upi': upi.text.trim(),
                'language': appLanguage.value,
              }, where: 'id=1');
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> showMsg(BuildContext context, String text) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('DokanMate'),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
      ],
    ),
  );
}